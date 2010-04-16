#import "CommandDispatcher.h"

@implementation CommandDispatcher

- (id) initWithSession:(LIBSSH2_SESSION *)newSession command:(char *)newCommand
{
    assert(self = [super init]);

    session = newSession;
    command = newCommand;

    exitCode = 0;

    stdoutResponse = [[NSMutableData alloc] init];
    stderrResponse = [[NSMutableData alloc] init];

    return self;
}

- (void) dealloc
{
    [self close];

    [stdoutResponse release];
    [stderrResponse release];

    [super dealloc];
}

- (bool) step
{
    static char buffer[0x4000];
    int rc;

    switch (step)
    {
        case 0:
            // Establish a command channel.

            channel = libssh2_channel_open_session(session);
            rc = libssh2_session_last_error(session, NULL, NULL, 0);
            exitCode = 127;

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (channel == NULL || rc != LIBSSH2_ERROR_NONE) return [self close];

            step++;

            return true;

        case 1:
            // Dispatch the command to the server.

            rc = libssh2_channel_exec(channel, command);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            step++;

            return true;

        case 2:
            // Read the response from the server.

            rc = libssh2_channel_read(channel, buffer, sizeof(buffer));

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];
                if (rc > 0) [stdoutResponse appendBytes:buffer length:rc];
            }

            rc = libssh2_channel_read_stderr(channel, buffer, sizeof(buffer));

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];
                if (rc > 0) [stderrResponse appendBytes:buffer length:rc];
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
