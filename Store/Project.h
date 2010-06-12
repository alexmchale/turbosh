#import <Foundation/Foundation.h>
#import "ProjectFile.h"

@class ProjectFile;

@interface Project : NSObject
{
    NSNumber *num;
    NSString *name;
    NSString *sshHost;
    NSNumber *sshPort;
    NSString *sshUser;
    NSString *sshPass;
    NSString *sshPath;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *sshHost;
@property (nonatomic, retain) NSNumber *sshPort;
@property (nonatomic, retain) NSString *sshUser;
@property (nonatomic, retain) NSString *sshPass;
@property (nonatomic, retain) NSString *sshPath;

+ (id) current;

- (id) loadCurrent;
- (id) loadByOffset:(NSInteger)offset;
- (NSArray *) files:(FileUsage)usage;
- (bool) existsInDatabase;

@end
