#import <Foundation/Foundation.h>
#import <libssh2.h>
#import <ProjectFile.h>

bool excluded_filename(NSString *filename);

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

- (NSArray *) files:(FileUsage)usage;
- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output;

@end
