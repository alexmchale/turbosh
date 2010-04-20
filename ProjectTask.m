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

- (id) initAsNumber:(NSNumber *)newNum
{
    assert(self = [self init]);

    self.num = newNum;

    if (self.num) assert([Store loadTask:self]);

    return self;
}

- (id) initAsNumber:(NSNumber *)newNum forProject:(Project *)myProject
{
    assert(self = [self init]);

    self.num = newNum;
    self.project = myProject;

    if (self.num) assert([Store loadTask:self]);

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
