#import "Synchronizer.h"

@implementation Synchronizer

@synthesize timer;

#pragma mark Synchronizer

- (void) step
{
}

#pragma mark Memory Management

- (id) init
{
    assert(self = [super init]);
    
    timer = nil;
    
    return self;
}

- (void) dealloc
{
    [timer release];
    
    [super dealloc];
}

@end
