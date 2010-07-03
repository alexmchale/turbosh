#import <Foundation/Foundation.h>

@interface FileLister : NSObject
{
    LIBSSH2_SESSION *session;
    NSString *command;

    Project *project;
    NSString *path;
    FileUsage mode;
    CommandDispatcher *dispatcher;
    NSMutableArray *files;
    int step;
}

@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSString *command;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) CommandDispatcher *dispatcher;
@property FileUsage mode;
@property int exitCode;

- (id) initWithProject:(Project *)p session:(LIBSSH2_SESSION *)s;
- (bool) step;
- (NSArray *) files;
- (bool) close;

@end
