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
    NSLog(@"init project %p", self);
    
    assert(self = [super init]);
    
    num = nil;
    name = nil;
    sshHost = nil;
    sshPort = nil;
    sshUser = nil;
    sshPass = nil;
    sshPath = nil;
    
    return self;
}

- (void) dealloc {
    NSLog(@"dealloc project %p", self);
    
    [num release];
    [name release];
    [sshHost release];
    [sshPort release];
    [sshUser release];
    [sshPass release];
    [sshPath release];
    
    [super dealloc];
}

-(oneway void)release {
    NSLog(@"Releasing %p, next count = %d", self, [self retainCount]-1);
    [super release];
}
-(id)retain {
    NSLog(@"Retaining %p, next count = %d", self, [self retainCount]+1);
    return [super retain];
}

@end
