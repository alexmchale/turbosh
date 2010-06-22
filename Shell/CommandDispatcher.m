#import "CommandDispatcher.h"

@implementation CommandDispatcher

@synthesize session;
@synthesize project;

- (NSString *) createCommand
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *scriptURL = [NSURL fileURLWithPath:[bundle pathForResource:@"command-script" ofType:@"sh" inDirectory:NO]];
    NSString *script = [[[NSString alloc] initWithContentsOfURL:scriptURL] autorelease];

    script = [script stringByReplacingOccurrencesOfString:@"___ROOT_PATH___" withString:[project.sshPath stringBySingleQuoting]];
    script = [script stringByReplacingOccurrencesOfString:@"___COMMAND___" withString:command];
    script = [script stringByReplacingOccurrencesOfRegex:@"[\r\n]" withString:@" "];
    script = [NSString stringWithFormat:@"sh -c %@", [script stringBySingleQuoting]];

    return script;
}

- (id) initWithProject:(Project *)newProject
               session:(LIBSSH2_SESSION *)newSession
               command:(NSString *)newCommand
{
    self = [super init];

    session = newSession;
    channel = NULL;

    project = newProject;
    [project retain];

    command = [newCommand retain];
    commandScript = [[self createCommand] retain];

    assert(project.sshPath);
    assert(command);

    exitCode = 0;

    stdoutResponse = [[NSMutableData alloc] init];
    stderrResponse = [[NSMutableData alloc] init];

    // Do not configure any environment variables for now.  SSHD disallows them by default.
    environ = [[NSMutableDictionary alloc] init];

    return self;
}

- (void) dealloc
{
    [self close];

    [project release];
    [command release];
    [commandScript release];
    [stdoutResponse release];
    [stderrResponse release];
    [environ release];
    [environKeys release];

    [super dealloc];
}

- (bool) step
{
    static char buffer[0x4000];
    int rc;
    char *errmsg;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    if (session == NULL) return false;

    libssh2_trace(session, 0xFFFFFFFF);
    libssh2_session_set_blocking(session, 0);

    switch (step)
    {
        case 0:
        {
            // Establish a command channel.

            channel = libssh2_channel_open_session(session);
            rc = libssh2_session_last_error(session, &errmsg, NULL, 0);
            exitCode = INT32_MAX;

            if (channel == NULL && rc == LIBSSH2_ERROR_EAGAIN) return true;

            [nc postNotificationName:@"begin" object:self];

            if (channel == NULL) return [self close];

            step++;
            environStep = 0;
            environKeys = [[environ allKeys] retain];

        }   return true;

        case 1:
        {
            // Send environment parameters to the server.

            if (environStep >= [environKeys count]) {
                step++;
                return true;
            }

            NSString *key = [environKeys objectAtIndex:environStep];
            NSString *val = [environ objectForKey:key];

            rc = libssh2_channel_setenv(channel, [key UTF8String], [val UTF8String]);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc < 0) return [self close];

            environStep++;

        }   return true;

        case 2:
        {
            // Request a PTY.

            const char *tt = "xterm-color";
            rc = libssh2_channel_request_pty_ex(channel, tt, strlen(tt), NULL, 0, 80, 20, 0, 0);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            step++;

        }   return true;

        case 3:
            // Dispatch the command to the server.

            rc = libssh2_channel_exec(channel, [commandScript UTF8String]);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            step++;

            return true;

        case 4:
            // Send an EOF to the server to indicate that no input will be provided.

            rc = libssh2_channel_send_eof(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            step++;

            return true;

        case 5:
            // Read the response from the server.

            rc = libssh2_channel_read(channel, buffer, sizeof(buffer) - 1);

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];

                if (rc > 0) {
                    buffer[rc] = '\0';

                    [stdoutResponse appendBytes:buffer length:rc];

                    NSString *str = [NSString stringWithUTF8String:buffer];
                    NSNumber *offset = [NSNumber numberWithInt:[stdoutResponse length]];
                    NSNumber *length = [NSNumber numberWithInt:rc];

                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @"stdout", @"type",
                                              str, @"string",
                                              offset, @"offset",
                                              length, @"length",
                                              nil];

                    [nc postNotificationName:@"progress" object:self userInfo:userInfo];
                }
            }

            rc = libssh2_channel_read_stderr(channel, buffer, sizeof(buffer) - 1);

            if (rc != LIBSSH2_ERROR_EAGAIN) {
                if (rc < 0) return [self close];

                if (rc > 0) {
                    buffer[rc] = '\0';

                    [stderrResponse appendBytes:buffer length:rc];

                    NSString *str = [NSString stringWithUTF8String:buffer];
                    NSNumber *offset = [NSNumber numberWithInt:[stderrResponse length]];
                    NSNumber *length = [NSNumber numberWithInt:rc];

                    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                              @"stderr", @"type",
                                              str, @"string",
                                              offset, @"offset",
                                              length, @"length",
                                              nil];

                    [nc postNotificationName:@"progress" object:self userInfo:userInfo];
                }
            }

            if (libssh2_channel_eof(channel)) step++;

            return true;

        case 6:
        {
            // Close the command channel.

            rc = libssh2_channel_close(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            exitCode = libssh2_channel_get_exit_status(channel);
            step++;

        } return [self close];

        default: return [self close];
    }
}

- (bool) close
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:exitCode], @"exit-code",
                              nil];

    [nc postNotificationName:@"finish" object:self userInfo:userInfo];

    session = NULL;

    if (channel != NULL) {
        libssh2_channel_free(channel);
        channel = NULL;
    }

    if (environKeys != nil) {
        [environKeys release];
        environKeys = nil;
    }

    step = 0;

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

- (NSString *) command {
    return command;
}

@end
