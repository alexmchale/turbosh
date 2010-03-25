#import <Foundation/Foundation.h>
#import "Project.h"

@class Project;

@interface ProjectFile : NSObject
{
    Project *proj;
    
    NSString *filename;
}

@property (nonatomic, retain) Project *proj;
@property (nonatomic, retain) NSString *filename;

- (NSString *)content;

@end
