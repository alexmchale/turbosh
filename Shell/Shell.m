#import "Shell.h"
#import <libssh2.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <arpa/inet.h>

static int waitsocket(int socket_fd, LIBSSH2_SESSION *session);

@implementation Shell

@synthesize project, timer;

- (id) initWithProject:(Project *)proj {

    self = [self init];

    running = true;
    queue = [[NSMutableArray alloc] init];
    failures = 0;

    self.project = proj;

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

// Start the event pump for this connection.
- (void) start {
    if (timer == nil) {
        if ([self connect]) {
            self.timer = [NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(pump:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
    }
}

// Stop the event pump.
- (void) stop {
    if (timer != nil) {
        [timer invalidate];
        self.timer = nil;

        [self disconnect];
    }
}

// Establish a new SSH connection.
- (bool) connect {
    struct sockaddr_in sin;
    int rc;

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
        return false;
    }

    // Configure LIBSSH2 for non-blocking communications.
    libssh2_session_set_blocking(session, 0);

    // Establish the SSH connection.
    while ((rc = libssh2_session_startup(session, sock)) == LIBSSH2_ERROR_EAGAIN)
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
        //continue;

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

    if (rc) {
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

// Push and pull data from the SSH connection.
- (void) pump:(NSTimer*)theTimer {
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
    int bytecount = 0;
    int rc;

    /* Exec non-blocking on the remove host */
    while((channel = libssh2_channel_open_session(session)) == NULL &&
          libssh2_session_last_error(session,NULL,NULL,0) == LIBSSH2_ERROR_EAGAIN) {
        //waitsocket(sock, session);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }

    if (channel == NULL) {
        NSLog(@"Error dispatching command: %@", command);
        return false;
    }

    while((rc = libssh2_channel_exec(channel, [command UTF8String])) == LIBSSH2_ERROR_EAGAIN) {
        //waitsocket(sock, session);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }

    if (rc) {
        NSLog(@"Error %d while executing command: %@", rc, command);
        return false;
    }

    for (;;) {
        /* loop until we block */
        int rc;
        do
        {
            char buffer[0x4000];
            rc = libssh2_channel_read(channel, buffer, sizeof(buffer));

            if (rc > 0) {
                [output appendBytes:buffer length:rc];
            }
        } while (rc > 0);

        if (rc != LIBSSH2_ERROR_EAGAIN)
            break;

        //waitsocket(sock, session);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
    }

    int exitcode = 127;

    while((rc = libssh2_channel_close(channel)) == LIBSSH2_ERROR_EAGAIN)
        //waitsocket(sock, session);
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];

    if (!rc) {
        exitcode = libssh2_channel_get_exit_status( channel );
    }

    NSLog(@"Executed command: %@", command);
    NSLog(@"Exit code %d with byte count %d", exitcode, bytecount);

    libssh2_channel_free(channel);
    channel = NULL;

    return exitcode == 0;
}

// Download the file at path.
- (NSData *) downloadFile:(NSString *)filePath {
    LIBSSH2_CHANNEL *channel;
    struct stat fileinfo;
    NSInteger downloaded = 0;
    NSMutableData *data = [NSMutableData data];
    const char *cFilename = [filePath UTF8String];
    int rc;

    NSLog(@"Downloading file: %@ %s", filePath, cFilename);

    libssh2_session_set_blocking(session, 1);

    if (!(channel = libssh2_scp_recv(session, cFilename, &fileinfo))) {
        char *errMsg;
        int errLen;
        libssh2_session_last_error(session, &errMsg, &errLen, 0);
        NSLog(@"Unable to open download session: %@", [NSString stringWithUTF8String:errMsg]);
        return nil;
    }

    while (downloaded < fileinfo.st_size) {
        char mem[1024];
        int packetSize = sizeof(mem);
        int remaining = fileinfo.st_size - downloaded;

        if (remaining < packetSize) packetSize = remaining;

        rc = libssh2_channel_read(channel, mem, packetSize);

        if (rc >= 0) {
            [data appendBytes:mem length:rc];
            downloaded += rc;
        } else if (rc != LIBSSH2_ERROR_EAGAIN) {
            data = nil;
            break;
        }
    }

    NSLog(@"Downloaded %d bytes with %d in data.", downloaded, [data length]);

    libssh2_channel_free(channel);
    channel = NULL;

    return data;
}

- (bool) uploadFile:(ProjectFile *)file
{
    LIBSSH2_CHANNEL *channel;
    const char *filePath = [[file fullpath] UTF8String];
    const NSData *contentData = [[file content] dataUsingEncoding:NSUTF8StringEncoding];
    const char *content = [contentData bytes];
    const int length = [contentData length];
    int sent = 0;

    NSLog(@"Uploading file %@", [file fullpath]);

    libssh2_session_set_blocking(session, 1);

    if (!(channel = libssh2_scp_send(session, filePath, 0777, length))) {
        char *errmsg;
        int errlen;
        int err = libssh2_session_last_error(session, &errmsg, &errlen, 0);
        NSLog(@"Unable to open upload session: %d", err);
        return false;
    }

    while (sent < length) {
        int packetSize = libssh2_channel_write(channel, &content[sent], 4096);

        if (packetSize < 0) {
            NSLog(@"Error %d sending: %@", packetSize, [file fullpath]);
            return false;
        }

        sent += packetSize;
    }

    libssh2_channel_send_eof(channel);
    libssh2_channel_wait_eof(channel);
    libssh2_channel_wait_closed(channel);

    libssh2_channel_free(channel);
    channel = NULL;

    NSLog(@"Sent %d bytes as: %@", length, [file fullpath]);

    return true;
}

- (NSString *) remoteMd5:(ProjectFile *)file
{
    NSString *md5Cmd = [NSString stringWithFormat:@"md5 %@ || md5sum %@", [file escapedPath], [file escapedPath]];
    NSMutableData *md5CmdResult = [NSMutableData data];
    bool md5Success = [self dispatchCommand:md5Cmd storeAt:md5CmdResult];

    NSLog(@"Remote MD5 command: %@", md5Cmd);

    if (!md5Success) return nil;
    if ([md5CmdResult length] < 32) return nil;

    char *cString = malloc([md5CmdResult length] + 1);
    memcpy(cString, [md5CmdResult bytes], [md5CmdResult length]);
    cString[[md5CmdResult length]] = '\0';
    NSString *md5String = [NSString stringWithUTF8String:cString];
    free(cString);

    NSString *md5Regex = @"[0-9a-fA-F]{32}";
    NSString *md5Match = [md5String stringByMatching:md5Regex];

    return md5Match;
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

static int waitsocket(int socket_fd, LIBSSH2_SESSION *session)
{
    struct timeval timeout;
    int rc;
    fd_set fd;
    fd_set *writefd = NULL;
    fd_set *readfd = NULL;
    int dir;

    timeout.tv_sec = 10;
    timeout.tv_usec = 0;

    FD_ZERO(&fd);

    FD_SET(socket_fd, &fd);

    /* now make sure we wait in the correct direction */
    dir = libssh2_session_block_directions(session);


    if(dir & LIBSSH2_SESSION_BLOCK_INBOUND)
        readfd = &fd;

    if(dir & LIBSSH2_SESSION_BLOCK_OUTBOUND)
        writefd = &fd;

    rc = select(socket_fd + 1, readfd, writefd, NULL, &timeout);

    return rc;
}

@end
