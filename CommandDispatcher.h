#import <Foundation/Foundation.h>
#import <libssh2.h>
#import <arpa/inet.h>

@interface CommandDispatcher : NSObject
{
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;
    NSString *command;
    NSString *pwdCommand;

    Project *project;

    int step;
    int exitCode;

    NSMutableData *stdoutResponse;
    NSMutableData *stderrResponse;
}

@property (nonatomic) LIBSSH2_SESSION *session;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSString *pwdCommand;

- (id) initWithProject:(Project *)project session:(LIBSSH2_SESSION *)session command:(NSString *)command;
- (bool) step;
- (int) exitCode;
- (NSData *) stdoutResponse;
- (NSData *) stderrResponse;
- (bool) close;
- (NSString *) getCommand;

@end
