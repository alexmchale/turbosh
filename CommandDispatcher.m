#import "CommandDispatcher.h"

@implementation CommandDispatcher

@synthesize session;
@synthesize project;

- (id) initWithSession:(LIBSSH2_SESSION *)newSession command:(NSString *)newCommand
{
    assert(self = [super init]);

    session = newSession;
    project = nil;

    command = newCommand;
    [command retain];

    exitCode = 0;

    stdoutResponse = [[NSMutableData alloc] init];
    stderrResponse = [[NSMutableData alloc] init];

    return self;
}

- (void) dealloc
{
    [self close];

    [project release];
    [command release];
    [stdoutResponse release];
    [stderrResponse release];

    [super dealloc];
}

- (bool) step
{
    static char buffer[0x4000];
    int rc;
    char *errmsg;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    if (session == NULL) return false;

    libssh2_session_set_blocking(session, 0);

    switch (step)
    {
        case 0:
            // Establish a command channel.

            channel = libssh2_channel_open_session(session);
            rc = libssh2_session_last_error(session, &errmsg, NULL, 0);
            exitCode = INT32_MAX;

            if (channel == NULL && rc == LIBSSH2_ERROR_EAGAIN) return true;

            if (channel == NULL) {
                fprintf(stderr, "command (%s) error (%d): %s\n", [command UTF8String], rc, errmsg);
                return [self close];
            }

            step++;

            return true;

        case 1:
            // Dispatch the command to the server.

            rc = libssh2_channel_exec(channel, [command UTF8String]);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            fprintf(stderr, "exec: %s\n", [command UTF8String]);

            step++;

            return true;

        case 2:
            // Read the response from the server.

            rc = libssh2_channel_read(channel, buffer, sizeof(buffer));

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];

                if (rc > 0) {
                    [stdoutResponse appendBytes:buffer length:rc];
                    [nc postNotificationName:@"CommandStdoutUpdate" object:self];
                }
            }

            rc = libssh2_channel_read_stderr(channel, buffer, sizeof(buffer));

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];

                if (rc > 0) {
                    [stderrResponse appendBytes:buffer length:rc];
                    [nc postNotificationName:@"CommandStderrUpdate" object:self];
                }
            }

            if (libssh2_channel_eof(channel)) step++;

            return true;

        case 3:
            // Close the command channel.

            rc = libssh2_channel_close(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            exitCode = libssh2_channel_get_exit_status(channel);
            step++;

            return [self close];

        default: return [self close];
    }
}

- (bool) close
{
    fprintf(stderr, "closing exec at step %d with exit code %d\n", step, exitCode);

    if (channel != NULL) {
        libssh2_channel_free(channel);
        channel = NULL;
    }

    return false;
}

- (int) exitCode {
    return exitCode;
}

- (NSData *) stdoutResponse {
    return stdoutResponse;
}

- (NSData *) stderrResponse {
    return stderrResponse;
}

@end
