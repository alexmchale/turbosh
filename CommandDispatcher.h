#import <Foundation/Foundation.h>
#import <libssh2.h>
#import <arpa/inet.h>

@interface CommandDispatcher : NSObject
{
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;
    NSString *command;

    Project *project;

    int step;
    int exitCode;

    NSMutableData *stdoutResponse;
    NSMutableData *stderrResponse;
}

@property (nonatomic) LIBSSH2_SESSION *session;
@property (nonatomic, retain) Project *project;

- (id) initWithSession:(LIBSSH2_SESSION *)session command:(NSString *)command;
- (bool) step;
- (int) exitCode;
- (NSData *) stdoutResponse;
- (NSData *) stderrResponse;
- (bool) close;

@end
