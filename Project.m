#import "Project.h"

@implementation Project

@synthesize num, name;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;

#pragma mark Data Loaders

- (id) loadCurrent {
    self.num = [Store currentProjectNum];
    assert([Store loadProject:self]);

    return self;
}

- (id) loadByOffset:(NSInteger)offset {
    self.num = [Store projectNumAtOffset:offset];
    assert([Store loadProject:self]);

    return self;
}

#pragma mark Memory Management

- (id) init
{
    assert(self = [super init]);

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
