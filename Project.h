#import <Foundation/Foundation.h>
#import "ProjectFile.h"

@class ProjectFile;

@interface Project : NSObject 
{
    NSNumber *num;
    NSString *name;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) NSString *name;

@end
