#import "TaskExecController.h"

@implementation TaskExecController

@synthesize webView, dispatcher, timer;

- (void) step
{
}

- (void) viewWillAppear:(BOOL)animated
{
    self.timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(step) userInfo:nil repeats:YES];
    [timer release];

    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [dispatcher close];

    [timer invalidate];
    self.timer = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    assert(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]);

    dispatcher = nil;
    timer = nil;

    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [webView release];
    [dispatcher release];
    [timer release];

    [super dealloc];
}

@end
