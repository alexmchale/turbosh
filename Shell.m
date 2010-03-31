#import "Shell.h"
#import <libssh2.h>
#import <arpa/inet.h>

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

    // Create the new socket.
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        fprintf(stderr, "failed to create socket %d\n", errno);
        return false;
    }

    // Set host parameters.
    sin.sin_family = AF_INET;
    sin.sin_port = htons([self.project.sshPort intValue]);
    sin.sin_addr.s_addr = inet_addr([self.project.sshHost UTF8String]);

    // Establish the TCP connection.
    if (connect(sock, (struct sockaddr *)&sin, sizeof(sin)) != 0) {
        fprintf(stderr, "failed to connect %d\n", errno);
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
        continue;
    if (rc) {
        fprintf(stderr, "Failure establishing SSH session: %d\n", rc);
        return nil;
    }

    // Authenticate using the configured password.
	const char *user = [project.sshUser UTF8String];
	const char *pass = [project.sshPass UTF8String];
    while ((rc = libssh2_userauth_password(session, user, pass)) == LIBSSH2_ERROR_EAGAIN)
        continue;
    if (rc) {
        fprintf(stderr, "Authentication by password failed.\n");
        return false;
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

// Executes and parses a find command on the remote server.
- (NSArray *) findFilesOfType:(char)type {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSMutableArray *files = nil;
    NSString *findCmd = [NSString stringWithFormat:@"find %@ -type %c -print0", [self escapedPath], type];

    if ([self dispatchCommand:findCmd storeAt:data]) {
        char *bytes = (char *)[data bytes];
        long offset = 0;
        files = [NSMutableArray array];

        while (offset < [data length]) {
            NSString *file = [NSString stringWithUTF8String:&bytes[offset]];
            file = [file substringFromIndex:[project.sshPath length]];
            [files addObject:file];
            offset += [file length] + 1;
        }
    }

    [data release];

    return files;
}

- (NSString *) escapedPath {
    return [project.sshPath stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
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
        waitsocket(sock, session);
    }

    if (channel == NULL) {
        fprintf(stderr,"Error\n");
        return false;
    }

    while((rc = libssh2_channel_exec(channel, [command UTF8String])) == LIBSSH2_ERROR_EAGAIN) {
        waitsocket(sock, session);
    }

    if (rc) {
        fprintf(stderr, "error %d while executing command: %s\n", rc, [command UTF8String]);
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

        waitsocket(sock, session);
    }

    int exitcode = 127;

    while((rc = libssh2_channel_close(channel)) == LIBSSH2_ERROR_EAGAIN)
        waitsocket(sock, session);

    if (!rc) {
        exitcode = libssh2_channel_get_exit_status( channel );
    }

    printf("\nEXIT: %d bytecount: %d\n", exitcode, bytecount);

    libssh2_channel_free(channel);
    channel = NULL;

    return true;
}

// Download the file at path.
- (NSData *) downloadFile:(NSString *)filePath {
    LIBSSH2_CHANNEL *channel;
    struct stat fileinfo;
    NSInteger downloaded = 0;
    NSMutableData *data = [NSMutableData data];
    int rc;
    
    fprintf(stderr, "downloading: %s\n", [filePath UTF8String]);
    
    libssh2_session_set_blocking(session, 1);
    
    if (!(channel = libssh2_scp_recv(session, [filePath UTF8String], &fileinfo))) {
        char *errMsg;
        int errLen;
        libssh2_session_last_error(session, &errMsg, &errLen, 0);
        fprintf(stderr, "unable to open a session: %s\n", errMsg);
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
    
    fprintf(stderr, "downloaded %d bytes with %d in data\n", downloaded, [data length]);
    
    libssh2_channel_free(channel);
    channel = NULL;
    
    return data;
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
