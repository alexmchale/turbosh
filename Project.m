#import "Project.h"

@implementation Project

@synthesize num, name;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;

#pragma mark Memory

- (id) initCurrent {
    if (self = [self init]) {
        self.num = [NSNumber numberWithInt:[Store currentProjectNum]];

        assert([Store loadProject:self]);
    }
    
    return self;
}

- (id) initByOffset:(NSInteger)offset {
    if (self = [self init]) {
        self.num = [Store projectNumAtOffset:offset];
        
        assert([Store loadProject:self]);
    }
    
    return self;
}

- (void) dealloc {
    [super dealloc];
    
    [num release];
    [name release];
    [sshHost release];
    [sshPort release];
    [sshUser release];
    [sshPass release];
    [sshPath release];
}

@end
