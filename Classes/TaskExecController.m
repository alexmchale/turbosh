#import "TaskExecController.h"

@implementation TaskExecController

@synthesize webView, dispatcher, timer;

#pragma mark Command Dispatcher Listeners

- (void) transferBegin:(NSNotification *)notif
{
    NSLog(@"Task Begin");
}

- (void) transferProgress:(NSNotification *)notif
{
    NSLog(@"Task Progress");
}

- (void) transferFinish:(NSNotification *)notif
{
    NSLog(@"Task Finish");
}

#pragma mark View Management

- (void) viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferProgress:)
                                                 name:@"progress" object:dispatcher];

    [SwiftCodeAppDelegate queueCommand:dispatcher];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [dispatcher close];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar
{
}

#pragma mark Memory Management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    assert(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]);

    dispatcher = nil;

    return self;
}

- (void)dealloc
{
    [webView release];
    [dispatcher release];

    [super dealloc];
}

@end
