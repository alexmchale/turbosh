#import <Foundation/Foundation.h>
#import <libssh2.h>

@class Project;

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

- (bool) dispatchCommand:(NSString *)command storeAt:(NSMutableData *)output;
- (NSData *) downloadFile:(NSString *)filePath;

- (NSString *) escapedPath;

@end
