#import "FileEditController.h"

@implementation FileEditController

@synthesize textView, text, startingRect;
@synthesize myToolbar, savedToolbarItems;

#pragma mark Button Actions

- (void) cancelAction
{
    [myToolbar setItems:savedToolbarItems];

    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [TurboshAppDelegate editFile:file atRect:textView.bounds];
    [file release];
}

- (void) saveAction
{
    self.text = textView.text;

    NSData *content = [text dataUsingEncoding:NSUTF8StringEncoding];
    [myToolbar setItems:savedToolbarItems];

    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [Store storeLocal:file content:content];
    [TurboshAppDelegate editFile:file atRect:textView.bounds];
    [file release];

    [TurboshAppDelegate sync];
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

#pragma mark Keyboard Resizing

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    keyboardShown = false;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (keyboardShown) return;

    NSDictionary* info = [aNotification userInfo];

    // Get the size of the keyboard.
    CGRect keyboardBounds;
    [[info valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    CGSize keyboardSize = keyboardBounds.size;

    NSLog(@"Keyboard Size: %fx%f", keyboardSize.width, keyboardSize.height);

    // Get the orientation of the device.
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;

    // Determine the amount by which to adjust the height.
    CGFloat heightAdjustment;
    if (UIDeviceOrientationIsLandscape(orient))
        heightAdjustment = keyboardSize.width;
    else
        heightAdjustment = keyboardSize.height;

    NSLog(@"Height Adjustment: %f\n", heightAdjustment);

    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = [textView frame];
    viewFrame.size.height -= heightAdjustment;
    textView.frame = viewFrame;

    [textView scrollRangeToVisible:[textView selectedRange]];

    keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    if (!keyboardShown) return;

    NSDictionary* info = [aNotification userInfo];

    // Get the size of the keyboard.
    CGRect keyboardBounds;
    [[info valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    CGSize keyboardSize = keyboardBounds.size;

    // Get the orientation of the device.
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;

    // Determine the amount by which to adjust the height.
    int heightAdjustment;
    if (UIDeviceOrientationIsLandscape(orient))
        heightAdjustment = keyboardSize.width;
    else
        heightAdjustment = keyboardSize.height;

    // Reset the height of the scroll view to its original value
    CGRect viewFrame = [textView frame];
    viewFrame.size.height += heightAdjustment;
    textView.frame = viewFrame;

    keyboardShown = NO;
}

#pragma mark View Events

- (void) viewWillAppear:(BOOL)animated
{
    textView.font = [UIFont fontWithName:@"Courier New" size:14.0];
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
}

- (void) viewDidDisappear:(BOOL)animated
{
    textView.text = @"";
}

- (void) viewDidLoad
{
    [self registerForKeyboardNotifications];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Memory Management

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    assert(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]);

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

    return self;
}

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

    NSMutableArray *a = [NSMutableArray arrayWithObjects:cancelButton, spacer, saveButton, nil];
    [toolbar setItems:a];
}

@end
