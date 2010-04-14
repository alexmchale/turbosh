#import <Foundation/Foundation.h>

@interface Synchronizer : NSObject
{
    NSTimer *timer;
}

@property (nonatomic, retain) NSTimer *timer;

- (void) step;

@end
