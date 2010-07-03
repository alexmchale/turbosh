#import "Project.h"

@implementation Project

#pragma mark Data Loaders

+ (id) current
{
    Project *project = [[[Project alloc] init] autorelease];

    [project loadCurrent];

    return project;
}

- (id) loadCurrent {
    self.num = [Store currentProjectNum];
    [Store loadProject:self];

    return self;
}

- (id) loadByOffset:(NSInteger)offset {
    self.num = [Store projectNumAtOffset:offset];
    [Store loadProject:self];

    return self;
}

- (NSArray *) files:(FileUsage)usage
{
    return [Store files:self ofUsage:usage];
}

#pragma mark Field Accessors

- (bool) existsInDatabase
{
    return [Store projectExists:self.num];
}

#pragma mark Memory Management

- (id) init
{
    self = [super init];

    self.sshPort = [[NSNumber alloc] initWithInt:22];

    return self;
}

- (void) dealloc {
    self.num = nil;
    self.name = nil;
    self.sshHost = nil;
    self.sshPort = nil;
    self.sshUser = nil;
    self.sshUser = nil;
    self.sshPass = nil;
    self.sshPath = nil;

    [super dealloc];
}

@end
