#import "FileViewController.h"

@implementation FileViewController

@synthesize webView, file;

 // The designated initializer.  Override if you create the controller programmatically and want to p
 // erform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
	NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
	NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"editor" ofType:@"html" inDirectory:NO]];
	NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];
    
    NSString *t = @"html";
    NSString *c = [NSString stringWithContentsOfURL:htmlURL];
    
    c = [c stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    c = [c stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    html = [html stringByReplacingOccurrencesOfString:@"___LANGUAGE___" withString:t];
    html = [html stringByReplacingOccurrencesOfString:@"___CONTENT___" withString:c];
    
    // ___LANGUAGE___
    // ___CONTENT___
	
	[webView loadHTMLString:html baseURL:baseURL];
    
    self.navigationItem.rightBarButtonItem = 
    [[[UIBarButtonItem alloc] 
      initWithBarButtonSystemItem:UIBarButtonSystemItemEdit 
      target:self 
      action:@selector(editDocument:)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated
{

}

- (void) viewDidAppear:(BOOL)animated
{
    123;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
