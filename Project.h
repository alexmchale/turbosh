#import <Foundation/Foundation.h>
#import "ProjectFile.h"

@class ProjectFile;

@interface Project : NSObject
{
    NSNumber *num;
    NSString *name;
    NSString *sshHostname;
    NSNumber *sshPort;
    NSString *sshUsername;
    NSString *sshPassword;
    NSString *sshPath;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *sshHostname;
@property (nonatomic, retain) NSNumber *sshPort;
@property (nonatomic, retain) NSString *sshUsername;
@property (nonatomic, retain) NSString *sshPassword;
@property (nonatomic, retain) NSString *sshPath;

@end
