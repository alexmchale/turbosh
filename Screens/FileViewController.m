#import "FileViewController.h"

@implementation FileViewController

@synthesize webView, file, startingRect;
@synthesize fontPicker = _fontPicker;
@synthesize fontPickerPopover = _fontPickerPopover;

- (void) loadFile
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *baseURL = [NSURL fileURLWithPath:[bundle resourcePath]];
    NSURL *htmlURL = [NSURL fileURLWithPath:[bundle pathForResource:@"editor" ofType:@"html" inDirectory:NO]];
    NSString *html = [[[NSString alloc] initWithContentsOfURL:htmlURL] autorelease];

    NSString *t = [file contentType];
    NSString *c = [file content];
    NSString *y = [NSString stringWithFormat:@"%d", (int)startingRect.origin.y];
    NSString *fs = [NSString stringWithFormat:@"%d", [Store fontSize]];

    if (!t || !c) {
        // Show a message and redirect to the project page.

        html = @"<br><br><br><center>That file is not yet loaded.</center>";

        [TurboshAppDelegate clearToolbar];
    } else {
        c = [c stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        c = [c stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        html = [html stringByReplacingOccurrencesOfString:@"___LANGUAGE___" withString:t];
        html = [html stringByReplacingOccurrencesOfString:@"___CONTENT___" withString:c];
        html = [html stringByReplacingOccurrencesOfString:@"___FONT_SIZE___" withString:fs];
        html = [html stringByReplacingOccurrencesOfString:@"___STARTING_OFFSET___" withString:y];
    }

    [webView loadHTMLString:html baseURL:baseURL];

    [Store setCurrentFile:file];
    [TurboshAppDelegate setLabelText:[file condensedPath]];
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

- (void) viewDidUnload
{
    self.file = nil;
}

- (void)dealloc
{
    self.webView = nil;
    self.file = nil;
    self.fontPicker = nil;
    self.fontPickerPopover = nil;

    [super dealloc];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar
{
    UIImage *fontButtonImage = [UIImage imageNamed:@"19-gear.png"];

    UIBarItem *spacer = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                          target:nil action:nil] autorelease];
    UIBarItem *font = [[[UIBarButtonItem alloc]
                          initWithImage:fontButtonImage
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(configureFont:)] autorelease];
    UIBarItem *edit = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                          target:self action:@selector(startEdit)] autorelease];

    NSMutableArray *items = [toolbar.items mutableCopy];
    [items addObject:spacer];
    [items addObject:font];
    [items addObject:edit];
    [toolbar setItems:items animated:YES];
    [items release];
}

#pragma mark Font Picker Delegate

- (void) fontChanged:(NSInteger)fontSize
{
    [self.fontPickerPopover dismissPopoverAnimated:YES];

    self.startingRect = CGRectMake(0, 0, webView.frame.size.width, webView.frame.size.height);
    [Store setFontSize:fontSize];
    [self loadFile];
}

#pragma mark File Editor Interface

- (void) configureFont:(id)sender
{
    if (_fontPicker == nil) {
        self.fontPicker =
            [[[FontPickerController alloc]
                initWithStyle:UITableViewStylePlain] autorelease];

        self.fontPicker.delegate = self;

        self.fontPickerPopover =
            [[[UIPopoverController alloc]
                initWithContentViewController:self.fontPicker] autorelease];
    }

    [self.fontPickerPopover
        presentPopoverFromBarButtonItem:sender
        permittedArrowDirections:UIPopoverArrowDirectionAny
        animated:YES];
}

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
