#import "Project.h"

@implementation Project

@synthesize identifier, name, fileIds;

- (ProjectFile *)fileAtIndex:(NSInteger)index
{
    ProjectFile *pf = [[[ProjectFile alloc] init] autorelease];
    
    pf.proj = self;
    pf.filename = [NSString stringWithFormat:@"path/to/file-%d.html", index];
    
    return pf;
}

- (NSInteger)fileCount
{
    return 50;
}

@end
