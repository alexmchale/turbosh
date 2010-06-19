#import "DetailViewController.h"
#import "RootViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CAMediaTimingFunction.h"

@interface DetailViewController ()
@property (nonatomic, retain) id popoverController;
@end

@implementation DetailViewController

@synthesize toolbar, popoverController, label, spinner, projectButton;

#pragma mark Switcher View Manager

- (void) clearToolbar
{
    if (projectButton)
        toolbar.items = [NSArray arrayWithObject:projectButton];
    else
        toolbar.items = [NSArray array];
}

- (void) adjustControllerSize:(UIViewController *)controller
{
    UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    int x, y;
    int width, height;

    x = 0;
    y = toolbarHeight;

    if (IS_IPAD || !UIInterfaceOrientationIsLandscape(orient)) {
        width = fr1.size.width;
        height = fr1.size.height - toolbarHeight;
    } else {
        width = fr1.size.height;
        height = fr1.size.width - toolbarHeight;
    }

    if (keyboardShown) {
        if (UIDeviceOrientationIsLandscape(orient))
            height -= keyboardSize.width;
        else
            height -= keyboardSize.height;
    }

    controller.view.frame = CGRectMake(x, y, width, height);

    if ([controller respondsToSelector:@selector(reload)]) [controller reload];
}

- (void) adjustCurrentController
{
    [self adjustControllerSize:currentController];
}

- (void)switchTo:(UIViewController<ContentPaneDelegate> *)controller
{
    // Adjust the incoming controller's view to match the available size.
    [self adjustControllerSize:controller];

    // Remove all controls from the toolbar except the popover button.
    if ([[toolbar items] count] > 0) {
        UIBarButtonItem *pb = [[toolbar items] objectAtIndex:0];
        [toolbar setItems:[NSArray arrayWithObjects:pb, nil]];
    } else {
        [toolbar setItems:[NSArray array]];
    }

    // View will appear / disappear.
    [currentController viewWillDisappear:YES];
    [controller viewWillAppear:YES];

    // Update the toolbar.
    [self clearToolbar];
    [controller viewSwitcher:self configureToolbar:toolbar];

    // Remove the current view and replace with the new one.
    [currentController.view removeFromSuperview];
    [self.view insertSubview:controller.view atIndex:0];

    // View did appear / disappear.
    [currentController viewDidDisappear:YES];
    [controller viewDidAppear:YES];

    // Set up an animation for the transition between the views.
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionFade];
    //[animation setSubtype:kCATransitionFromTop];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

    [[self.view layer] addAnimation:animation forKey:@"SwitchToView1"];

    [controller retain];
    [currentController release];
    currentController = controller;

    [popoverController dismissPopoverAnimated:YES];
}

#pragma mark Split view support

// Add the popover button to the button bar.
- (void) splitViewController:(UISplitViewController*)svc
      willHideViewController:(UIViewController *)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem
        forPopoverController:(UIPopoverController*)pc
{
    self.projectButton = barButtonItem;

    barButtonItem.title = @"Project";
    barButtonItem.tag = TAG_PROJECT_BUTTON;

    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];

    self.popoverController = pc;
}

// Remove the popover button from the button bar.
- (void) splitViewController:(UISplitViewController*)svc
      willShowViewController:(UIViewController *)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.projectButton = nil;

    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObject:barButtonItem];
    [toolbar setItems:items animated:YES];
    [items release];

    self.popoverController = nil;
}

#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Keyboard Listeners

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    keyboardShown = true;

    // Get the size of the keyboard.
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardBounds;
    [[info valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    keyboardSize = keyboardBounds.size;

    [self adjustControllerSize:currentController];
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    keyboardShown = false;

    // Get the size of the keyboard.
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardBounds;
    [[info valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
    keyboardSize = keyboardBounds.size;

    [self adjustControllerSize:currentController];
}

#pragma mark View lifecycle

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self adjustControllerSize:currentController];

    [currentController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void) viewDidLoad
{
    keyboardShown = false;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.popoverController = nil;
    self.toolbar = nil;
    self.projectButton = nil;
}

#pragma mark Memory management

- (void)dealloc {
    [popoverController release];
    [currentController release];
    [toolbar release];
    [label release];
    [spinner release];
    [projectButton release];

    [super dealloc];
}

@end
