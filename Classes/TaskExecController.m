#import "TaskExecController.h"

@implementation TaskExecController

@synthesize webView, dispatcher, timer;

#pragma mark Command Dispatcher Listeners

- (void) transferBegin:(NSNotification *)notif
{
    NSLog(@"Task Begin");

    NSString *c = [[dispatcher command] stringByQuotingJavascript];
    NSString *js = [NSString stringWithFormat:@"printBegin(%@);", c];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) transferProgress:(NSNotification *)notif
{
    NSLog(@"Task Progress");
    NSLog(@"%@", [notif.userInfo valueForKey:@"string"]);

    NSString *c = [notif.userInfo valueForKey:@"string"];
    c = [c stringByConvertingAnsiColor];
    c = [c stringByQuotingJavascript];
    NSString *js = [NSString stringWithFormat:@"printProgress(%@);", c];

    NSLog(@"%@", js);

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) transferFinish:(NSNotification *)notif
{
    NSLog(@"Task Finish");

    NSNumber *c = [notif.userInfo valueForKey:@"exit-code"];
    NSString *js = [NSString stringWithFormat:@"printFinish('%@');", c];

    [webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark View Management

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
    NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"task-viewer" ofType:@"html" inDirectory:NO]];
    NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];

    [webView loadHTMLString:html baseURL:baseURL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferBegin:)
                                                 name:@"begin" object:dispatcher];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferProgress:)
                                                 name:@"progress" object:dispatcher];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferFinish:)
                                                 name:@"finish" object:dispatcher];

    [SwiftCodeAppDelegate queueCommand:dispatcher];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self];
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
