#import "Synchronizer.h"
#import <libssh2.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <arpa/inet.h>

#define SYNCHRONIZE_DELAY_SECONDS 0.05

@implementation Synchronizer

@synthesize timer;
@synthesize project, file;
@synthesize dispatcher, transfer;
@synthesize pendingCommand;

#pragma mark Synchronizer

- (void) selectProject
{
    NSNumber *num = [Store projectNumAfterNum:project.num];

    self.file = nil;
    self.project = nil;
    nextFileOffset = 0;

    if (num == nil) {
        state = SS_IDLE;
        return;
    }

    self.project = [[Project alloc] init];
    [project release];

    self.project.num = num;

    assert([Store loadProject:project]);

    state = SS_CONNECT_TO_SERVER;
}

- (void) connectToServer
{
    struct sockaddr_in sin;

    // Verify that the current project has a server configured.
    if (!project || !project.sshHost || !project.sshPort ||
            !project.sshUser || !project.sshPass || !project.sshPath ||
            [project.sshHost length] == 0) {
        state = SS_SELECT_PROJECT;
        return;
    }

    // Create the new socket.
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        fprintf(stderr, "failed to create socket %d\n", errno);
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

    // Establish the TCP connection.
    if (connect(sock, (struct sockaddr *)&sin, sizeof(sin)) != 0) {
        fprintf(stderr, "failed to connect %d\n", errno);
        state = SS_DISCONNECT;
        return;
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
        fprintf(stderr, "Failure establishing SSH session: %d\n", rc);
        state = SS_TERMINATE_SSH;
        return;
    }

    state = SS_AUTHENTICATE_SSH;
}

- (void) authenticateSsh
{
    // Authenticate using the configured password.
    const char *user = [project.sshUser UTF8String];
    const char *pass = [project.sshPass UTF8String];

    int rc = libssh2_userauth_password(session, user, pass);

    if (rc == LIBSSH2_ERROR_EAGAIN) return;

    if (rc != 0) {
        fprintf(stderr, "Authentication by password failed.\n");
        state = SS_TERMINATE_SSH;
        return;
    }

    if (!pendingCommand.projectNum || [project.num isEqualToNumber:pendingCommand.projectNum])
        state = SS_EXECUTE_COMMAND;
    else
        state = SS_SELECT_FILE;
}

- (void) executeCommand
{
    if (![pendingCommand step]) {
        state = SS_TERMINATE_SSH;
        self.pendingCommand = nil;
    }
}

- (void) selectFile
{
    self.file = [[ProjectFile alloc] init];
    [file release];

    self.file.num = [Store projectFileNumber:project atOffset:nextFileOffset];
    self.file.project = project;

    nextFileOffset++;

    if (file.num == nil) {
        state = SS_TERMINATE_SSH;
        return;
    }

    assert([Store loadProjectFile:file]);

    state = SS_INITIATE_HASH;
}

- (void) initiateHash
{
    NSString *md5f = @"md5 %@ || md5sum %@";
    NSString *md5Cmd = [NSString stringWithFormat:md5f, [file escapedPath], [file escapedPath]];

    self.dispatcher = [[CommandDispatcher alloc] initWithSession:session command:md5Cmd];

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
    assert(false);
}

- (void) testIfChanged
{
    NSData *md5Data = [dispatcher stdoutResponse];
    NSString *remoteMd5 = [[NSString alloc] initWithData:md5Data encoding:NSASCIIStringEncoding];
    NSString *md5Regex = @"[0-9a-fA-F]{32}";
    NSString *md5 = [[remoteMd5 stringByMatching:md5Regex] uppercaseString];

    bool lEl = [file.localMd5 isEqualToString:file.remoteMd5];
    bool lEr = [file.localMd5 isEqualToString:md5];
    bool rEr = [file.remoteMd5 isEqualToString:md5];

    [remoteMd5 release];
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
        assert(false);
    }
}

- (void) initiateUpload
{
    fprintf(stderr, "uploading %s\n", [file.filename UTF8String]);

    self.transfer = [[FileTransfer alloc] initWithSession:session upload:file];
    [transfer release];

    state = SS_CONTINUE_TRANSFER;
}

- (void) initiateDownload
{
    fprintf(stderr, "downloading %s\n", [file.filename UTF8String]);

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
    if (session != NULL) {
        libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(session);
        session = NULL;
    }

    state = SS_DISCONNECT;
}

- (void) disconnect
{
    close(sock);
    sock = 0;

    state = SS_SELECT_PROJECT;
}

- (void) idle
{
    self.project = nil;
    self.file = nil;
    self.dispatcher = nil;
    self.transfer = nil;

    if (startup) {
        startup = false;
        state = SS_SELECT_PROJECT;
    } else if (pendingCommand.projectNum) {
        self.project = [[Project alloc] init];
        project.num = pendingCommand.projectNum;
        assert([Store loadProject:project]);
        [project release];

        state = SS_CONNECT_TO_SERVER;
    }
}

- (void) step
{
    if (project == nil && state != SS_IDLE) state = SS_SELECT_PROJECT;

    switch (state) {
        case SS_SELECT_PROJECT:         return [self selectProject];
        case SS_CONNECT_TO_SERVER:      return [self connectToServer];
        case SS_ESTABLISH_SSH:          return [self establishSsh];
        case SS_AUTHENTICATE_SSH:       return [self authenticateSsh];
        case SS_EXECUTE_COMMAND:        return [self executeCommand];
        case SS_SELECT_FILE:            return [self selectFile];
        case SS_INITIATE_HASH:          return [self initiateHash];
        case SS_CONTINUE_HASH:          return [self continueHash];
        case SS_COMPLETE_HASH:          return [self completeHash];
        case SS_FILE_IS_MISSING:        return [self fileIsMissing];
        case SS_TEST_IF_CHANGED:        return [self testIfChanged];
        case SS_INITIATE_UPLOAD:        return [self initiateUpload];
        case SS_INITIATE_DOWNLOAD:      return [self initiateDownload];
        case SS_CONTINUE_TRANSFER:      return [self continueTransfer];
        case SS_COMPLETE_TRANSFER:      return [self completeTransfer];
        case SS_TERMINATE_SSH:          return [self terminateSsh];
        case SS_DISCONNECT:             return [self disconnect];
        case SS_IDLE:                   return [self idle];

        default: assert(false);
    }
}

- (void) synchronize
{
    startup = true;
}

#pragma mark Memory Management

- (id) init
{
    assert(self = [super init]);

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
    startup = false;
    pendingCommand = nil;

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

    [super dealloc];
}

@end
