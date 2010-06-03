#import "Project.h"

@implementation Project

@synthesize num, name;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;

#pragma mark Data Loaders

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

#pragma mark Field Accessors

- (bool) existsInDatabase
{
    return [Store projectExists:num];
}

#pragma mark Memory Management

- (id) init
{
    self = [super init];

    num = nil;
    name = nil;
    sshHost = nil;
    sshPort = [[NSNumber alloc] initWithInt:22];
    sshUser = nil;
    sshPass = nil;
    sshPath = nil;

    return self;
}

- (void) dealloc {
    [num release];
    [name release];
    [sshHost release];
    [sshPort release];
    [sshUser release];
    [sshPass release];
    [sshPath release];

    [super dealloc];
}

@end
