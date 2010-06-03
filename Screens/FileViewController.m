#import "FileViewController.h"

@implementation FileViewController

@synthesize webView, file, startingRect;

- (void) loadFile
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
    NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"editor" ofType:@"html" inDirectory:NO]];
    NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];

    NSString *t = [file contentType];
    NSString *c = [file content];
    NSString *y = [NSString stringWithFormat:@"%d", (int)startingRect.origin.y];

    if (!t || !c) {
        // Show a message and redirect to the project page.

        html = @"<br><br><br><center>That file is not yet loaded.</center>";

        [TurboshAppDelegate clearToolbar];
    } else {
        c = [c stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        c = [c stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        html = [html stringByReplacingOccurrencesOfString:@"___LANGUAGE___" withString:t];
        html = [html stringByReplacingOccurrencesOfString:@"___CONTENT___" withString:c];
        html = [html stringByReplacingOccurrencesOfString:@"___STARTING_OFFSET___" withString:y];
    }

    [webView loadHTMLString:html baseURL:baseURL];

    [TurboshAppDelegate setLabelText:[file condensedPath]];
}

// The designated initializer.  Override if you create the controller
// programmatically and want to perform customization that is not
// appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        file = nil;
    }

    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem =
        [[[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
          target:self
          action:@selector(editDocument:)] autorelease];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self loadFile];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

#pragma mark Memory Management

- (void)dealloc {
    [webView release];
    [file release];

    [super dealloc];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    UIBarItem *spacer = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                          target:nil action:nil] autorelease];
    UIBarItem *edit = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                          target:self action:@selector(startEdit)] autorelease];

    NSMutableArray *items = [toolbar.items mutableCopy];
    [items addObject:spacer];
    [items addObject:edit];
    [toolbar setItems:items animated:YES];
    [items release];
}

#pragma mark File Editor Interface

- (void) startEdit
{
    NSString *r = [webView stringByEvaluatingJavaScriptFromString:@"getCurrentScrollPosition()"];
    NSInteger y = [r integerValue];

    FileEditController *fec = [[FileEditController alloc] initWithNibName:@"FileEditController" bundle:nil];

    fec.text = file.content;
    fec.startingRect = CGRectMake(0, y, webView.frame.size.width, webView.frame.size.height);

    [TurboshAppDelegate switchTo:fec];

    [fec release];
}

@end
