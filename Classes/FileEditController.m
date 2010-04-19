#import "FileEditController.h"

@implementation FileEditController

@synthesize textView, text, startingRect;
@synthesize myToolbar, savedToolbarItems;
@synthesize cancelButton, spacer, saveButton;

#pragma mark Button Actions

- (void) cancelAction
{
    [myToolbar setItems:savedToolbarItems];
    [SwiftCodeAppDelegate editCurrentFile];
}

- (void) saveAction
{
    self.text = textView.text;

    NSData *content = [text dataUsingEncoding:NSASCIIStringEncoding];

    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [Store storeLocal:file content:content];
    [file release];

    [myToolbar setItems:savedToolbarItems];
    [SwiftCodeAppDelegate editCurrentFile];

    [SwiftCodeAppDelegate sync];
}

#pragma mark View Events

- (void) viewWillAppear:(BOOL)animated
{
    textView.font = [UIFont fontWithName:@"Courier New" size:16.0];
    textView.text = text;
}

- (void) viewDidAppear:(BOOL)animated
{
    [textView scrollRectToVisible:startingRect animated:NO];
}

- (void) viewDidDisappear:(BOOL)animated
{
    textView.text = @"";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Memory Management

- (void)dealloc
{
    [text release];
    [textView release];

    [myToolbar release];
    [savedToolbarItems release];

    [cancelButton release];
    [spacer release];
    [saveButton release];

    [super dealloc];
}

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar
{
    self.myToolbar = toolbar;
    self.savedToolbarItems = [toolbar items];

    cancelButton =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
         target:self
         action:@selector(cancelAction)];

    spacer =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
         target:nil
         action:nil];

    saveButton =
        [[UIBarButtonItem alloc]
         initWithBarButtonSystemItem:UIBarButtonSystemItemSave
         target:self
         action:@selector(saveAction)];

    NSMutableArray *a = [NSMutableArray arrayWithObjects:cancelButton, spacer, saveButton, nil];
    [toolbar setItems:a];
}

@end
