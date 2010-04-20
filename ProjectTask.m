#import "ProjectTask.h"

@implementation ProjectTask

@synthesize num, project;
@synthesize name, script;

#pragma mark Memory Management

- (id) init
{
    assert(self = [super init]);

    num = nil;
    project = nil;
    name = nil;
    script = nil;

    return self;
}

- (void) dealloc
{
    [num release];
    [project release];
    [name release];
    [script release];

    [super dealloc];
}

@end
