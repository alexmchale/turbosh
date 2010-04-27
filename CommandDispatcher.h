#import <Foundation/Foundation.h>
#import <libssh2.h>
#import <arpa/inet.h>

@interface CommandDispatcher : NSObject
{
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;
    NSString *command;

    NSNumber *projectNum;

    int step;
    int exitCode;

    NSMutableData *stdoutResponse;
    NSMutableData *stderrResponse;
}

@property (nonatomic, retain) NSNumber *projectNum;

- (id) initWithSession:(LIBSSH2_SESSION *)session command:(NSString *)command;
- (bool) step;
- (int) exitCode;
- (NSData *) stdoutResponse;
- (NSData *) stderrResponse;
- (bool) close;

@end
