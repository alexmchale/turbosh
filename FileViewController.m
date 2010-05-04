#import "FileViewController.h"

@implementation FileViewController

@synthesize webView, file, startingRect;
@synthesize myToolbar, savedToolbar;

// The designated initializer.  Override if you create the controller
// programmatically and want to perform customization that is not
// appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        file = nil;
        myToolbar = nil;
        savedToolbar = nil;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
    NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"editor" ofType:@"html" inDirectory:NO]];
    NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];

    NSString *t = [file contentType];
    NSString *c = [file content];
    NSString *y = [NSString stringWithFormat:@"%d", (int)startingRect.origin.y];

    c = [c stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    c = [c stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    html = [html stringByReplacingOccurrencesOfString:@"___LANGUAGE___" withString:t];
    html = [html stringByReplacingOccurrencesOfString:@"___CONTENT___" withString:c];
    html = [html stringByReplacingOccurrencesOfString:@"___STARTING_OFFSET___" withString:y];

    [webView loadHTMLString:html baseURL:baseURL];

    [SwiftCodeAppDelegate setLabelText:[file condensedPath]];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [myToolbar setItems:savedToolbar];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [webView release];
    [file release];
    [myToolbar release];
    [savedToolbar release];

    [super dealloc];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    self.myToolbar = toolbar;
    self.savedToolbar = [toolbar items];

    UIBarItem *spacer = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                          target:nil action:nil] autorelease];
    UIBarItem *edit = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                          target:self action:@selector(startEdit)] autorelease];

    NSMutableArray *items = [savedToolbar mutableCopy];
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

    [SwiftCodeAppDelegate switchTo:fec];

    [fec release];
}

@end
