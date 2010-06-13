#import "Shell.h"
#import <libssh2.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <arpa/inet.h>
#include <unistd.h>

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
    if (authPassword == NULL) return;
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

bool excluded_filename(NSString *filename)
{
    static NSString *exclRegex = @"\\.git|\\.svn|\\.hg|\\.\\.";
    const NSRange range = [filename rangeOfRegex:exclRegex];
    return range.location != NSNotFound;
}

// Executes and parses a find command on the remote server.
- (NSArray *) files:(FileUsage)usage
{
    FileLister *fl = [[FileLister alloc] initWithProject:project session:session];

    fl.path = @".";
    fl.mode = usage;

    while ([fl step])
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];

    NSArray *files = [fl files];

    [fl release];

    return files;
}

#pragma mark Connection Drivers

// Blocks while the command is being run.
- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output
{
    CommandDispatcher *cd =
        [[CommandDispatcher alloc]
            initWithProject:project
            session:session
            command:command];

    while ([cd step])
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];

    bool success = cd.exitCode == 0;

    if (success) {
        [output setLength:0];
        [output appendData:[cd stdoutResponse]];
    }

    [cd release];

    return success;
}

@end
