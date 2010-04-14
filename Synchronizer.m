#import "Synchronizer.h"

#define SYNCHRONIZE_DELAY_SECONDS 0.25

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

    timer = [NSTimer timerWithTimeInterval:SYNCHRONIZE_DELAY_SECONDS
                                    target:self
                                  selector:@selector(step)
                                  userInfo:nil
                                   repeats:YES];
    [timer retain];
    
    return self;
}

- (void) dealloc
{
    [timer release];
    
    [super dealloc];
}

@end
