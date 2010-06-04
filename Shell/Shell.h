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
    int sock;
    LIBSSH2_SESSION *session;
}

@property (nonatomic, retain) Project *project;

- (id) initWithProject:(Project *)proj;

- (bool) connect;
- (void) disconnect;

- (NSArray *) directories;
- (NSArray *) files;
- (NSArray *) executables;
- (NSArray *) findFilesOfType:(char)type;
- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output;
- (NSString *) escapedPath;

+ (NSArray *) fetchProjectFileList:(Project *)p;

@end
