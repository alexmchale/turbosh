#import "FileEditController.h"

@implementation FileEditController

@synthesize textView, text, startingRect;
@synthesize cancelButton, spacer, saveButton;

#pragma mark Button Actions

- (void) cancelAction
{
    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [TurboshAppDelegate editFile:file atRect:textView.bounds];
    [file release];
}

- (void) saveAction
{
    self.text = textView.text;

    NSData *content = [text dataWithAutoEncoding];

    assert(content);
    if (!content) return;

    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [Store storeLocal:file content:content];
    [TurboshAppDelegate editFile:file atRect:textView.bounds];
    [file release];

    [TurboshAppDelegate sync:file.project.num];
}

#pragma mark Edit Events

- (void) textViewDidChange:(UITextView *)textView
{
}

- (void) textViewDidBeginEditing:(UITextView *)textView
{
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
}

#pragma mark View Events

- (void) viewDidLoad
{
    self.cancelButton =
        [[[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
         target:self
         action:@selector(cancelAction)] autorelease];

    self.spacer =
        [[[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
         target:nil
         action:nil] autorelease];

    self.saveButton =
        [[[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemSave
         target:self
         action:@selector(saveAction)] autorelease];
}

- (void) viewWillAppear:(BOOL)animated
{
    textView.font = [UIFont fontWithName:@"Courier New" size:[Store fontSize]];
    textView.text = text;

    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [TurboshAppDelegate setLabelText:[file condensedPath]];
    [file release];
}

- (void) viewDidAppear:(BOOL)animated
{
    [textView scrollRectToVisible:startingRect animated:NO];
    NSLog(@"Now editing with scroll at (%d, %d) (%f, %f).", startingRect.origin.x, startingRect.origin.y, startingRect.size.width, startingRect.size.height);
}

- (void) viewDidDisappear:(BOOL)animated
{
    textView.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark Memory Management

- (void) viewDidUnload
{
    self.cancelButton = nil;
    self.spacer = nil;
    self.saveButton = nil;
}

- (void)dealloc
{
    [text release];
    [textView release];

    [cancelButton release];
    [spacer release];
    [saveButton release];

    [super dealloc];
}

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar
{
    [toolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, saveButton, nil]];
}

@end
