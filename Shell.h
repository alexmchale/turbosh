#import <Foundation/Foundation.h>
#import <libssh2.h>

@interface Shell : NSObject 
{
    NSString *hostname;
    NSInteger port;
    NSString *username;
    NSString *password;
    
    bool running;
    NSMutableArray *queue;
    int failures;
    
    NSTimer *timer;
    int sock;
    LIBSSH2_SESSION *session;
}

@property (nonatomic, retain) NSString *hostname;
@property NSInteger port;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) NSTimer *timer;

- (id) initWithCredentials:(NSString *)h
                      port:(NSInteger)n
                  username:(NSString *)u
                  password:(NSString *)p;

- (NSArray *) fetchFileList;

- (bool) connect;
- (void) disconnect;

- (NSArray *) directories;
- (NSArray *) files;
- (NSArray *) findFilesOfType:(char)type;

- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output;

- (NSString *) escapedPath;

@end
