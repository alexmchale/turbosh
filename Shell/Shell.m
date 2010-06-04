#import "Shell.h"
#import <libssh2.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <arpa/inet.h>

@implementation Shell

@synthesize project;

- (id) initWithProject:(Project *)proj
{
    self = [self init];

    project = [proj retain];

    return self;
}

// The function kbd_callback is needed for keyboard-interactive authentication via LIBSSH2.
static char *authPassword = NULL;
static void kbd_callback(const char *name, int name_len,
                         const char *instruction, int instruction_len, int num_prompts,
                         const LIBSSH2_USERAUTH_KBDINT_PROMPT *prompts,
                         LIBSSH2_USERAUTH_KBDINT_RESPONSE *responses,
                         void **abstract)
{
    if (authPassword == NULL);
    if (num_prompts != 1 || strstr(prompts[0].text, "assword") == NULL) return;

    responses[0].text = authPassword;
    responses[0].length = strlen(authPassword);

    authPassword = NULL;
}

#pragma mark Connection Management

// Establish a new SSH connection.
- (bool) connect {
    struct sockaddr_in sin;
    int rc;

    // Verify that we have somewhere to connect to.
    if (!project || !project.sshHost || !project.sshPort ||
        !project.sshUser || !project.sshPass || !project.sshPath) {
        return false;
    }

    // Create the new socket.
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        NSLog(@"Failed to create socket %d", errno);
        return false;
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
        NSLog(@"Failed to connect %d", errno);
        return false;
    }

    // Begin a new SSH session.
    if (!(session = libssh2_session_init())) {
        NSLog(@"Unable to create the SSH2 session.");
        return false;
    }

    // Configure LIBSSH2 for non-blocking communications.
    libssh2_session_set_blocking(session, 0);

    // Establish the SSH connection.
    do {
        rc = libssh2_session_startup(session, sock);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (rc == LIBSSH2_ERROR_EAGAIN);

    if (rc) {
        NSLog(@"Failure establishing SSH session: %d", rc);
        return nil;
    }

    // Authenticate using the configured password.
    do {
        const char *user = [project.sshUser UTF8String];
        const char *pass = [project.sshPass UTF8String];
        rc = libssh2_userauth_password(session, user, pass);

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (rc == LIBSSH2_ERROR_EAGAIN);

    if (rc != LIBSSH2_ERROR_NONE) {
        NSLog(@"Authentication by password failed, trying interactive.");

        do {
            if (authPassword != NULL) free(authPassword);
            authPassword = strdup([project.sshPass UTF8String]);

            const char *user = [project.sshUser UTF8String];
            rc = libssh2_userauth_keyboard_interactive(session, user, &kbd_callback);

            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
        } while (rc == LIBSSH2_ERROR_EAGAIN);

        if (rc != LIBSSH2_ERROR_NONE) {
            NSLog(@"Authentication by keyboard-interactive failed.");
            return false;
        }
    }

    return true;
}

// Disconnect the SSH session.
- (void) disconnect {
    libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
    libssh2_session_free(session);

    close(sock);
}

#pragma mark File Queying

// List all directories for this shell path.
- (NSArray *) directories {
    return [self findFilesOfType:'d'];
}

// List all regular files for this shell path.
- (NSArray *) files {
    return [self findFilesOfType:'f'];
}

static bool excluded_filename(NSString *filename) {
    static NSString *exclRegex = @"\\.git|\\.svn|\\.hg";
    const NSRange range = [filename rangeOfRegex:exclRegex];
    return range.location != NSNotFound;
}

// Executes and parses a find command on the remote server.
- (NSArray *) findFilesOfType:(char)type {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSMutableArray *files = nil;
    NSString *testCmd = [NSString stringWithFormat:@"test -d %@", [self escapedPath]];
    NSString *findCmd = [NSString stringWithFormat:@"find %@ -type %c -print0", [self escapedPath], type];
    NSString *cmd = [NSString stringWithFormat:@"%@ && %@", testCmd, findCmd];

    NSLog(@"Find command: %@", cmd);

    if ([self dispatchCommand:cmd storeAt:data]) {
        char *bytes = (char *)[data bytes];
        long length = [data length];
        long pathLength = (project.sshPath ? [project.sshPath length] : 0) + 1;
        long offset = 0;

        files = [NSMutableArray array];

        while (offset < length) {
            NSString *file = [NSString stringWithCString:&bytes[offset] encoding:NSUTF8StringEncoding];

            if (pathLength < [file length]) {
                file = [file substringFromIndex:pathLength];

                if (!excluded_filename(file)) [files addObject:file];
            }

            // Scan to 1 past the NULL.
            while (offset < length && bytes[offset] != '\0')
                offset++;
            offset++;
        }
    }

    [data release];

    return files;
}

// Finds executables in the project path.
- (NSArray *) executables {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSMutableArray *files = nil;
    NSString *ep = [self escapedPath];
    NSString *testCmd = [NSString stringWithFormat:@"test -d %@", ep];
    NSString *findCmd = [NSString stringWithFormat:@"find %@ -type f -perm -100 -print0", ep];
    NSString *cmd = [NSString stringWithFormat:@"%@ && %@", testCmd, findCmd];

    NSLog(@"Find Command: %@", cmd);

    if ([self dispatchCommand:cmd storeAt:data]) {
        char *bytes = (char *)[data bytes];
        long length = [data length];
        long pathLength = (project.sshPath ? [project.sshPath length] : 0) + 1;
        long offset = 0;

        files = [NSMutableArray array];

        while (offset < length) {
            NSString *file = [NSString stringWithCString:&bytes[offset] encoding:NSUTF8StringEncoding];

            if (pathLength < [file length]) {
                file = [file substringFromIndex:pathLength];

                if (!excluded_filename(file)) [files addObject:file];
            }

            // Scan to 1 past the NULL.
            while (offset < length && bytes[offset] != '\0')
                offset++;
            offset++;
        }
    }

    [data release];

    return files;
}

- (NSString *) escapedPath {
    if (!project.sshPath || [@"" isEqualToString:project.sshPath])
        return @".";

    return [project.sshPath stringBySingleQuoting];
}

#pragma mark Connection Drivers

// Blocks while the command is being run.
- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output {
    LIBSSH2_CHANNEL *channel;
    int rc;

    show_alert(@"Debug", @"Opening channel");

    /* Exec non-blocking on the remove host */
    do {
        channel = libssh2_channel_open_session(session);
        rc = libssh2_session_last_error(session, NULL, NULL, 0);

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (channel == NULL && rc == LIBSSH2_ERROR_EAGAIN);

    if (channel == NULL) {
        NSLog(@"Error dispatching command: %@", command);
        return false;
    }

    show_alert(@"Debug", @"Starting execution");

    do {
        rc = libssh2_channel_exec(channel, [command UTF8String]);

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (rc == LIBSSH2_ERROR_EAGAIN);

    if (rc != LIBSSH2_ERROR_NONE) {
        NSLog(@"Error %d while executing command: %@", rc, command);
        libssh2_channel_free(channel);
        return false;
    }

    show_alert(@"Debug", @"Reading response");

    char buffer[0x4000];
    do {
        rc = libssh2_channel_read(channel, buffer, sizeof(buffer));

        if (rc > 0) [output appendBytes:buffer length:rc];

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (rc > 0 || rc == LIBSSH2_ERROR_EAGAIN);

    int exitcode = 127;

    show_alert(@"Debug", @"Closing channel");

    do {
        rc = libssh2_channel_close(channel);

        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    } while (rc == LIBSSH2_ERROR_EAGAIN);

    if (rc == LIBSSH2_ERROR_NONE)
        exitcode = libssh2_channel_get_exit_status( channel );

    show_alert(@"Debug", @"Dispatch complete");

    NSLog(@"Executed command: %@", command);
    NSLog(@"Exit code %d with byte count %d", exitcode, [output length]);

    libssh2_channel_free(channel);
    channel = NULL;

    return exitcode == 0;
}

#pragma mark Wrapper Tasks

+ (NSArray *) fetchProjectFileList:(Project *)p
{
    Shell *s = [[Shell alloc] initWithProject:p];
    NSArray *f = nil;

    if ([s connect]) {
        f = [s files];
        [s disconnect];
    }

    [s release];

    return f;
}

@end
