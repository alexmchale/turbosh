#import <Foundation/Foundation.h>
#import "Project.h"

@class Project;

@interface ProjectFile : NSObject
{
    NSNumber *num;
    Project *proj;
    NSString *filename;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) Project *proj;
@property (nonatomic, retain) NSString *filename;

- (ProjectFile *)initByNumber:(NSNumber *)number;
- (NSString *)content;

@end
