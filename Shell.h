#import <Foundation/Foundation.h>
#import <libssh2.h>

typedef enum {
    SCR_SUCCESS,
    SCR_CONNECTION_FAILED,
    SCR_COMMAND_FAILED
} ShellCommandResult;

@class Project;
@class ProjectFile;

@interface Shell : NSObject 
{
	Project *project;
    
    bool running;
    NSMutableArray *queue;
    int failures;
    
    NSTimer *timer;
    int sock;
    LIBSSH2_SESSION *session;
}

@property (nonatomic, retain) Project *project;

@property (nonatomic, retain) NSTimer *timer;

- (id) initWithProject:(Project *)proj;

- (bool) connect;
- (void) disconnect;

- (NSArray *) directories;
- (NSArray *) files;
- (NSArray *) findFilesOfType:(char)type;
- (NSString *) remoteMd5:(ProjectFile *)file;

- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output;
- (NSData *) downloadFile:(NSString *)filePath;
- (bool) uploadFile:(ProjectFile *)file;

- (NSString *) escapedPath;

+ (NSArray *) fetchProjectFileList:(Project *)p;

@end
