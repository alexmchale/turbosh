#import "FileLister.h"

@implementation FileLister

@synthesize command, project, path, mode, dispatcher;

- (id) initWithProject:(Project *)newProject
               session:(LIBSSH2_SESSION *)newSession
{
    self = [super init];

    session = newSession;

    project = newProject;
    [project retain];

    step = 0;
    files = nil;
    dispatcher = nil;
    command = nil;
    path = nil;

    return self;
}

- (void) dealloc
{
    [self close];

    [project release];
    [path release];
    [command release];
    [dispatcher release];
    [files release];

    [super dealloc];
}

- (NSString *) createCommand
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *scriptURL = [NSURL fileURLWithPath:[bundle pathForResource:@"find-script" ofType:@"sh" inDirectory:NO]];
    NSString *script = [[[NSString alloc] initWithContentsOfURL:scriptURL] autorelease];

    NSString *cf = nil;

    if (mode == FU_FILE) cf = @"-type f -print0";
    if (mode == FU_TASK) cf = @"-type f -perm -100 -print0";
    if (mode == FU_PATH) cf = @"-type d -print0";

    if (cf != nil) {
        cf = [cf stringBySingleQuoting];
        NSString *cp = [self.path stringBySingleQuoting];

        script = [script stringByReplacingOccurrencesOfString:@"___TARGET_PATH___" withString:cp];
        script = [script stringByReplacingOccurrencesOfString:@"___FIND_PARAMETERS___" withString:cf];
        return script;
    }

    return nil;
}

- (bool) close
{
    [dispatcher close];

    step = 0;
    self.command = nil;
    self.dispatcher = nil;

    return false;
}

- (bool) step
{
    switch (step) {
        // Set up the command to execute.
        case 0:
            self.command = [self createCommand];

            self.dispatcher =
                [[CommandDispatcher alloc]
                     initWithProject:project
                     session:session
                     command:command];

            [files release];
            files = nil;

            step++;

            return true;

        // Execute the command.
        case 1:
            if (![dispatcher step]) step++;

            return true;

        // Parse the results.
        case 2:
        {
            // Exit codes >1 are permission/existence errors.
            if (dispatcher.exitCode > 1) return [self close];

            NSData *data = [dispatcher stdoutResponse];
            const char *bytes = [data bytes];
            const long length = [data length];
            long offset = 0;

            files = [[NSMutableArray alloc] init];

            while (offset < length) {
                NSString *file = [NSString stringWithCString:&bytes[offset] encoding:NSUTF8StringEncoding];

                NSRange dotSlash = [file rangeOfString:@"./"];
                if (dotSlash.location == 0) file = [file substringFromIndex:2];

                if (!excluded_filename(file)) [files addObject:file];

                // Scan to 1 past the NULL.
                while (offset < length && bytes[offset] != '\0')
                    offset++;
                offset++;
            }

            [files sortUsingSelector:@selector(caseInsensitiveCompare:)];

            step++;

            return true;
        }

        default:
            self.dispatcher = nil;
            self.command = nil;

            return false;
    }
}

- (NSArray *) files { return [[files retain] autorelease]; }

@end
