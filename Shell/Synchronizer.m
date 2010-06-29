#import "Synchronizer.h"
#import <libssh2.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <termios.h>

#define SHOW_SYNC_LOG false
#define SYNCHRONIZE_DELAY_SECONDS 0.05

@implementation Synchronizer

@synthesize timer;
@synthesize project, file, projectsToSync;
@synthesize dispatcher, transfer, lister;
@synthesize currentCommand;

#pragma mark Utility Functions

// The function kbd_callback is needed for keyboard-interactive authentication via LIBSSH2.
static char *authPassword = NULL;
static NSLock *kbd_callback_lock = nil;
static void kbd_callback(const char *name, int name_len,
                         const char *instruction, int instruction_len, int num_prompts,
                         const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts,
                         LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
                         void **abstract)
{
    if (authPassword == NULL) return;
    if (num_prompts != 1 || strstr(prompts[0].text, "assword") == NULL) return;

    responses[0].text = authPassword;
    responses[0].length = strlen(authPassword);

    authPassword = NULL;
}

#pragma mark Synchronizer

- (void) selectProject
{
    NSNumber *num = nil;

    if (projectsToSync) {
        if ([projectsToSync count] == 0) {
            self.projectsToSync = nil;
            state = SS_IDLE;
            return;
        }

        num = [[[projectsToSync objectAtIndex:0] retain] autorelease];
        [projectsToSync removeObjectAtIndex:0];
    } else {
        num = [Store projectNumAfterNum:project.num];
    }

    self.file = nil;
    self.project = nil;
    nextFileOffset = 0;

    if (num == nil) {
        self.project = nil;
        state = SS_IDLE;
        return;
    }

    self.project = [[Project alloc] init];
    [project release];

    self.project.num = num;

    [Store loadProject:project];

    state = SS_BEGIN_CONN;
}

- (void) beginConnection
{
    // Verify that the current project has a server configured.
    if (!project || !project.sshHost || !project.sshPort ||
            !project.sshUser || !project.sshPath ||
            [project.sshHost length] == 0) {
        state = SS_SELECT_PROJECT;
        return;
    }

    // Create the new socket.
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        NSLog(@"Failed to create socket %d", errno);
        state = SS_SELECT_PROJECT;
        return;
    }

    // Resolve the address of the server.
    struct hostent *host = gethostbyname([project.sshHost UTF8String]);
    in_addr_t ip;
    if (host && host->h_addr_list[0] != NULL)
        memcpy(&ip, host->h_addr_list[0], sizeof(in_addr_t));
    else
        ip = inet_addr([project.sshHost UTF8String]);

    // Set host parameters.
    sin.sin_family = AF_INET;
    sin.sin_port = htons([self.project.sshPort intValue]);
    sin.sin_addr.s_addr = ip;

    if (fcntl(sock, F_SETFL, O_NONBLOCK) < 0) {
        NSLog(@"FCNTL error when setting non-blocking socket: %s", strerror(errno));
        state = SS_TERMINATE_SSH;
        return;
    }

    state = SS_ESTABLISH_CONN;
}

- (void) establishConnection
{
    int rc = connect(sock, (struct sockaddr *)&sin, sizeof(sin));

    if (rc != 0) {
        if (errno == EAGAIN || errno == EINPROGRESS || errno == EALREADY) return;

        if (errno != EISCONN) {
            NSLog(@"Failed to connect (%d): %s", errno, strerror(errno));

            state = SS_DISCONNECT;
            return;
        }
    }

    state = SS_ESTABLISH_SSH;
}

- (void) establishSsh
{
    if (session == NULL) {
        // Begin a new SSH session.

        session = libssh2_session_init();

        if (session == NULL) {
            state = SS_DISCONNECT;
            return;
        }

        // Configure LIBSSH2 for non-blocking communications.
        libssh2_session_set_blocking(session, 0);
    }

    // Establish the SSH connection.
    int rc = libssh2_session_startup(session, sock);

    if (rc == LIBSSH2_ERROR_EAGAIN) return;

    if (rc != 0) {
        NSLog(@"Failure establishing SSH session: %d", rc);
        state = SS_TERMINATE_SSH;
        return;
    }

    state = SS_REQUEST_AUTH_TYPE;
}

- (void) requestAuthType
{
    const char *user = [project.sshUser UTF8String];
    const int userlen = [project.sshUser length];
    const char *authlist = libssh2_userauth_list(session, user, userlen);
    const int rc = libssh2_session_last_errno(session);

    if (!authlist) {
        if (rc == LIBSSH2_ERROR_EAGAIN) return;

        NSLog(@"Failure reading authentication types from server: %d", rc);
        state = SS_TERMINATE_SSH;
        return;
    }

    if (authPassword != NULL) free(authPassword);
    authPassword = NULL;
    if (project.sshPass) authPassword = strdup([project.sshPass UTF8String]);

    NSLog(@"Valid authentication modes for server: %s", authlist);

    authType.password = strstr(authlist, "password") != NULL;
    authType.interactive = strstr(authlist, "keyboard-interactive") != NULL;
    authType.publickey = strstr(authlist, "publickey") != NULL;

    state = SS_AUTHENTICATE_SSH_BY_KEY;
}

- (void) authenticateSshByKey
{
    // Verify that we have connection parameters.
    if (!project.sshUser) {
        state = SS_TERMINATE_SSH;
        return;
    }

    // Authenticate using the stored SSH key.
    KeyPair *key = [[KeyPair alloc] init];
    const char *user = [project.sshUser UTF8String];
    const char *privateKey = [[key privateFilename] UTF8String];
    const char *publicKey = [[key publicFilename] UTF8String];

    int rc = libssh2_userauth_publickey_fromfile(session, user, publicKey, privateKey, NULL);

    [key release];

    if (rc == LIBSSH2_ERROR_EAGAIN) return;

    if (rc != LIBSSH2_ERROR_NONE) {
        NSLog(@"Authentication by key failed: %d", rc);
        state = SS_AUTHENTICATE_SSH_BY_PASSWORD;
        return;
    }

    if (currentCommand && [project.num isEqualToNumber:currentCommand.project.num])
        state = SS_EXECUTE_COMMAND;
    else
        state = SS_INITIATE_LIST;
}

- (void) authenticateSshByPassword
{
    // Verify that we have connection parameters.
    if (!authPassword || !project.sshUser || !project.sshPass) {
        state = SS_TERMINATE_SSH;
        return;
    }

    // Authenticate using the configured password.
    const char *user = [project.sshUser UTF8String];
    const char *pass = [project.sshPass UTF8String];

    if (authType.password) {
        int rc = libssh2_userauth_password(session, user, pass);

        if (rc == LIBSSH2_ERROR_EAGAIN) return;

        if (rc != LIBSSH2_ERROR_NONE) {
            NSLog(@"Authentication by password failed.");
            state = SS_TERMINATE_SSH;
            return;
        }
    } else if (authType.interactive) {
        int rc;

        @synchronized(kbd_callback_lock) {
            rc = libssh2_userauth_keyboard_interactive(session, user, &kbd_callback);
        }

        if (rc == LIBSSH2_ERROR_EAGAIN) return;

        if (rc != LIBSSH2_ERROR_NONE) {
            NSLog(@"Authentication by keyboard-interactive failed.");
            state = SS_TERMINATE_SSH;
            return;
        }
    } else {
        // TODO: Show an error message.

        NSLog(@"No valid authentication mode was found.");
        state = SS_TERMINATE_SSH;
        return;
    }

    if (currentCommand && [project.num isEqualToNumber:currentCommand.project.num])
        state = SS_EXECUTE_COMMAND;
    else
        state = SS_INITIATE_LIST;
}

- (void) executeCommand
{
    currentCommand.session = session;

    if (![currentCommand step]) {
        self.currentCommand = nil;
        self.project = nil;
        self.file = nil;
        startup = true;
        state = SS_TERMINATE_SSH;
    }
}

- (void) initiateList
{
    self.file = [[ProjectFile alloc] init];
    [file release];

    self.file.num = [Store projectFileNumber:project atOffset:nextFileOffset ofUsage:FU_PATH];
    self.file.project = project;

    nextFileOffset++;

    if (file.num == nil) {
        self.file = nil;
        nextFileOffset = 0;
        state = SS_SELECT_FILE;
        return;
    }

    [Store loadProjectFile:file];

    self.lister = [[FileLister alloc] initWithProject:project session:session];
    [lister release];

    lister.mode = FU_FILE;
    lister.path = file.filename;

    state = SS_CONTINUE_LIST;
}

- (void) continueList
{
    if ([lister step]) return;

    NSArray *files = [lister files];

    if (!files) return;

    ProjectFile *newFile = [[ProjectFile alloc] init];

    for (NSString *filename in files) {
        [newFile loadByProject:project filename:filename forUsage:FU_FILE];
        if (!newFile.num) {
            [Store storeProjectFile:newFile];
            [TurboshAppDelegate reloadList];
        }
    }

    [newFile release];

    state = SS_INITIATE_LIST;
}

- (void) selectFile
{
    self.file = [[ProjectFile alloc] init];
    [file release];

    self.file.num = [Store projectFileNumber:project atOffset:nextFileOffset ofUsage:FU_FILE];
    self.file.project = project;

    nextFileOffset++;

    if (file.num == nil) {
        self.file = nil;
        state = SS_TERMINATE_SSH;
        return;
    }

    [Store loadProjectFile:file];

    if (file.remoteMd5 && [file.remoteMd5 length] == 32)
        state = SS_INITIATE_HASH;
    else
        state = SS_INITIATE_DOWNLOAD;
}

- (void) initiateHash
{
    NSString *md5f = @"md5 %@ ; e=$?; if [ $e -eq 127 ]; then exec md5sum %@; else exit $e; fi";
    NSString *pat = [file escapedRelativePath];
    NSString *md5Cmd = [NSString stringWithFormat:md5f, pat, pat];
    NSString *shCmd = [NSString stringWithFormat:@"sh -c %@", [md5Cmd stringBySingleQuoting]];

    self.dispatcher = [[CommandDispatcher alloc] initWithProject:project session:session command:shCmd];
    [dispatcher release];

    state = SS_CONTINUE_HASH;
}

- (void) continueHash
{
    if (![dispatcher step]) state = SS_COMPLETE_HASH;
}

- (void) completeHash
{
    switch ([dispatcher exitCode]) {
        case INT32_MAX:
            // The connection failed and the command did not execute.
            state = SS_TERMINATE_SSH;
            break;

        case 127:
        {
            // Neither md5 command was found.

            NSString *tit = @"Command Missing";
            NSString *msg = @"Neither the commands md5 nor md5sum could be found on the server.  Please install one of them and try again.";
            show_alert(tit, msg);

            state = SS_AWAITING_ANSWER;
        }   break;

        case 0:
            // The command succeeded.
            state = SS_TEST_IF_CHANGED;
            break;

        default:
            // The command ran but the file could not be hashed.
            state = SS_FILE_IS_MISSING;
            break;
    }
}

- (void) fileIsMissing
{
    // Prompt the user to delete or upload.

    NSString *tit = @"File Missing";
    NSString *msg =
    [NSString
     stringWithFormat:@"The file %@ does not exist on the remote server.  What would you like to do?",
     file.filename];

    UIAlertView *charAlert = [[UIAlertView alloc]
                              initWithTitle:tit
                              message:msg
                              delegate:self
                              cancelButtonTitle:@"Upload"
                              otherButtonTitles:@"Delete", nil];
    charAlert.tag = TAG_FILE_MISSING;
    [charAlert show];
    [charAlert autorelease];

    state = SS_AWAITING_ANSWER;
}

- (void) deleteLocalFile
{
    if (file) {
        [Store deleteProjectFile:file];
        self.file = nil;
        [TurboshAppDelegate reloadList];

        state = SS_SELECT_FILE;
    }
}

- (void) testIfChanged
{
    NSData *md5Data = [dispatcher stdoutResponse];
    NSString *remoteMd5 = [md5Data stringWithAutoEncoding];
    NSString *md5 = [remoteMd5 findMd5];

    bool lEl = [file.localMd5 isEqualToString:file.remoteMd5];
    bool lEr = [file.localMd5 isEqualToString:md5];
    bool rEr = [file.remoteMd5 isEqualToString:md5];

    self.dispatcher = nil;

    if (rEr && lEr) {
        // The file is unchanged.  Move to the next one.
        state = SS_SELECT_FILE;
    } else if (file.remoteMd5 == nil) {
        // The file has never existed locally.  Download it.
        state = SS_INITIATE_DOWNLOAD;
    } else if (rEr && !lEr) {
        // The file did not change on the server, but it did locally.
        state = SS_INITIATE_UPLOAD;
    } else if (lEl && !rEr) {
        // The file changed on the server but not locally.
        state = SS_INITIATE_DOWNLOAD;
    } else {
        // The file changed in both locations.  Prompt the user what to do.

        NSString *tit = @"File Conflict";
        NSString *msg =
            [NSString
             stringWithFormat:@"The file %@ has changed both locally and on the remote server.  What would you like to do?",
             file.filename];

        UIAlertView *charAlert = [[UIAlertView alloc]
                                  initWithTitle:tit
                                  message:msg
                                  delegate:self
                                  cancelButtonTitle:@"Upload"
                                  otherButtonTitles:@"Download", nil];
        charAlert.tag = TAG_FILE_CONFLICT;
        [charAlert show];
        [charAlert autorelease];

        state = SS_AWAITING_ANSWER;
    }
}

- (void) initiateUpload
{
    NSLog(@"Uploading %@", file.filename);

    self.transfer = [[FileTransfer alloc] initWithSession:session upload:file];
    [transfer release];

    state = SS_CONTINUE_TRANSFER;
}

- (void) initiateDownload
{
    NSLog(@"Downloading %@", file.filename);

    self.transfer = [[FileTransfer alloc] initWithSession:session download:file];
    [transfer release];

    state = SS_CONTINUE_TRANSFER;
}

- (void) continueTransfer
{
    if (![transfer step]) state = SS_COMPLETE_TRANSFER;
}

- (void) completeTransfer
{
    if ([transfer succeeded])
        state = SS_SELECT_FILE;
    else
        state = SS_TERMINATE_SSH;

    self.transfer = nil;
}

- (void) terminateSsh
{
    [dispatcher close];
    self.dispatcher = nil;

    [lister close];
    self.lister = nil;

    if (session != NULL) {
        libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(session);
        session = NULL;
    }

    if (project && ![project existsInDatabase]) self.project = nil;
    if (file && ![file existsInDatabase]) self.file = nil;

    if (!currentCommand && [pendingCommands count] > 0) {
        self.currentCommand = [pendingCommands objectAtIndex:0];
        self.project = currentCommand.project;
        [pendingCommands removeObjectAtIndex:0];
    }

    state = SS_DISCONNECT;
}

- (void) disconnect
{
    if (sock != 0) {
        close(sock);
        sock = 0;
    }

    state = currentCommand ? SS_BEGIN_CONN : SS_SELECT_PROJECT;
}

- (void) idle
{
    self.project = nil;
    self.file = nil;
    self.dispatcher = nil;
    self.transfer = nil;

    [currentCommand close];
    self.currentCommand = nil;

    if (startup) {
        startup = false;
        state = SS_SELECT_PROJECT;
    } else if ([pendingCommands count] > 0) {
        self.currentCommand = [pendingCommands objectAtIndex:0];
        self.project = currentCommand.project;
        [pendingCommands removeObjectAtIndex:0];

        state = SS_BEGIN_CONN;
    }
}

- (void) step
{
    // Adjust the state if we don't have a project and we're not idle.
    if (project == nil && state != SS_IDLE) state = SS_SELECT_PROJECT;
    if (state != SS_IDLE && SHOW_SYNC_LOG) NSLog(@"Synchronizer At %d", state);
    if (project && ![project existsInDatabase]) state = SS_TERMINATE_SSH;
    if (file && ![file existsInDatabase]) state = SS_TERMINATE_SSH;

    [TurboshAppDelegate spin:(state != SS_IDLE)];

    // Abort this connection if there's a command ready and we're not connected for it.
    if (currentCommand && project && ![project.num isEqualToNumber:currentCommand.project.num]) {
        state = SS_TERMINATE_SSH;
    } else if (!currentCommand && [pendingCommands count] > 0) {
        state = SS_TERMINATE_SSH;
    }

    // Post a notification of the synchronizer's current state.
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:state] forKey:@"state"];
    if (project) [userInfo setObject:project forKey:@"project"];
    if (file) [userInfo setObject:file forKey:@"file"];
    if (state == SS_EXECUTE_COMMAND && currentCommand) [userInfo setObject:currentCommand forKey:@"task"];
    [nc postNotificationName:@"sync-state" object:self userInfo:userInfo];
    [userInfo release];

    // Execute the appropriate callback for this state.
    switch (state) {
        case SS_SELECT_PROJECT:         return [self selectProject];
        case SS_BEGIN_CONN:             return [self beginConnection];
        case SS_ESTABLISH_CONN:         return [self establishConnection];
        case SS_ESTABLISH_SSH:          return [self establishSsh];
        case SS_REQUEST_AUTH_TYPE:      return [self requestAuthType];
        case SS_AUTHENTICATE_SSH_BY_KEY:        return [self authenticateSshByKey];
        case SS_AUTHENTICATE_SSH_BY_PASSWORD:   return [self authenticateSshByPassword];
        case SS_EXECUTE_COMMAND:        return [self executeCommand];
        case SS_INITIATE_LIST:          return [self initiateList];
        case SS_CONTINUE_LIST:          return [self continueList];
        case SS_SELECT_FILE:            return [self selectFile];
        case SS_INITIATE_HASH:          return [self initiateHash];
        case SS_CONTINUE_HASH:          return [self continueHash];
        case SS_COMPLETE_HASH:          return [self completeHash];
        case SS_FILE_IS_MISSING:        return [self fileIsMissing];
        case SS_TEST_IF_CHANGED:        return [self testIfChanged];
        case SS_DELETE_LOCAL_FILE:      return [self deleteLocalFile];
        case SS_INITIATE_UPLOAD:        return [self initiateUpload];
        case SS_INITIATE_DOWNLOAD:      return [self initiateDownload];
        case SS_CONTINUE_TRANSFER:      return [self continueTransfer];
        case SS_COMPLETE_TRANSFER:      return [self completeTransfer];
        case SS_TERMINATE_SSH:          return [self terminateSsh];
        case SS_DISCONNECT:             return [self disconnect];
        case SS_AWAITING_ANSWER:        return;
        case SS_IDLE:                   return [self idle];

        default: assert(false);
    }
}

- (SyncState) state { return state; }

- (void) stop
{
    [currentCommand close];
    self.currentCommand = nil;

    [dispatcher close];
    self.dispatcher = nil;

    [lister close];
    self.lister = nil;

    [transfer close];
    self.transfer = nil;

    self.projectsToSync = nil;
    self.project = nil;
    self.file = nil;

    startup = false;
    [pendingCommands removeAllObjects];

    if (session != NULL) {
        libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(session);
        session = NULL;
    }

    if (sock != 0) {
        close(sock);
        sock = 0;
    }

    state = SS_IDLE;
}

- (void) synchronize
{
    startup = true;
}

- (void) synchronize:(NSNumber *)projectNumber
{
    startup = true;

    if (projectNumber) {
        if (!projectsToSync)
            self.projectsToSync = [NSMutableArray array];

        if (![projectsToSync containsObject:projectNumber])
            [projectsToSync addObject:projectNumber];
    }
}

- (void) appendCommand:(CommandDispatcher *)command
{
    [pendingCommands addObject:command];
}

#pragma mark Alert View Delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case TAG_FILE_CONFLICT:
            if (buttonIndex == 0)
                state = SS_INITIATE_UPLOAD;
            else
                state = SS_INITIATE_DOWNLOAD;
            break;

        case TAG_FILE_MISSING:
            if (buttonIndex == 0)
                state = SS_INITIATE_UPLOAD;
            else
                state = SS_DELETE_LOCAL_FILE;
            break;

        case TAG_MD5_COMMAND_MISSING:
            state = SS_TERMINATE_SSH;
            break;
    }
}

#pragma mark Memory Management

- (id) init
{
    self = [super init];

    if (!kbd_callback_lock) kbd_callback_lock = [[NSLock alloc] init];

    timer = [NSTimer timerWithTimeInterval:SYNCHRONIZE_DELAY_SECONDS
                                    target:self
                                  selector:@selector(step)
                                  userInfo:nil
                                   repeats:YES];
    [timer retain];

    state = SS_SELECT_PROJECT;

    project = nil;
    file = nil;
    dispatcher = nil;
    transfer = nil;
    lister = nil;
    startup = false;

    currentCommand = nil;
    pendingCommands = [[NSMutableArray alloc] init];
    projectsToSync = nil;

    sock = 0;
    session = NULL;

    return self;
}

- (void) dealloc
{
    [timer release];
    [project release];
    [file release];
    [dispatcher release];
    [transfer release];
    [lister release];
    [currentCommand release];
    [pendingCommands release];
    [projectsToSync release];

    [super dealloc];
}

@end
