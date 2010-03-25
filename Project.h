#import <Foundation/Foundation.h>
#import "ProjectFile.h"

@class ProjectFile;

@interface Project : NSObject 
{
    NSInteger identifier;
    
    NSString *name;
    NSArray *fileIds;
}

@property NSInteger identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *fileIds;

- (ProjectFile *)fileAtIndex:(NSInteger)index;
- (NSInteger)fileCount;

@end
