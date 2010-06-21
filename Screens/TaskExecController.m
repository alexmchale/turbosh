#import "TaskExecController.h"

@implementation TaskExecController

@synthesize webView, dispatcher, timer;

#pragma mark Command Dispatcher Listeners

- (void) clearWindow
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
    NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"task-viewer" ofType:@"html" inDirectory:NO]];
    NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];

    [webView loadHTMLString:html baseURL:baseURL];
}

- (void) transferBegin:(NSNotification *)notif
{
    NSString *c = [[dispatcher command] stringByQuotingJavascript];
    NSString *js = [NSString stringWithFormat:@"printBegin(%@);", c];

    NSLog(@"Task Begin");
    NSLog(@"%@", js);

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) transferProgress:(NSNotification *)notif
{
    NSString *c = [notif.userInfo valueForKey:@"string"];
    c = [c stringByConvertingAnsiColor];
    c = [c stringByQuotingJavascript];
    NSString *js = [NSString stringWithFormat:@"printProgress(%@);", c];

    NSLog(@"Task Progress");
    NSLog(@"c: %@", c);
    NSLog(@"j: %@", js);

    [webView stringByEvaluatingJavaScriptFromString:js];
}

- (void) transferFinish:(NSNotification *)notif
{
    NSNumber *c = [notif.userInfo valueForKey:@"exit-code"];
    NSString *js = [NSString stringWithFormat:@"printFinish('%@');", c];

    NSLog(@"Task Finish");
    NSLog(@"%@", js);

    [webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark View Management

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferBegin:)
                                                 name:@"begin" object:dispatcher];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferProgress:)
                                                 name:@"progress" object:dispatcher];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(transferFinish:)
                                                 name:@"finish" object:dispatcher];

    [TurboshAppDelegate queueCommand:dispatcher];
    [TurboshAppDelegate setLabelText:@"Task Launcher"];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self clearWindow];
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

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
}

#pragma mark Memory Management

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

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
