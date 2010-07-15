#import "DetailViewController.h"
#import "RootViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CAMediaTimingFunction.h"

@implementation DetailViewController

@synthesize toolbar, popoverController, label, spinner, projectButton;

#pragma mark Switcher View Manager

- (void) updateOrientation
{
    UIDeviceOrientation newOrient = [CURRENT_DEVICE orientation];

    if (UIDeviceOrientationIsValidInterfaceOrientation(newOrient)) orient = newOrient;
}

- (void) clearToolbar
{
    if (projectButton)
        toolbar.items = [NSArray arrayWithObject:projectButton];
    else
        toolbar.items = [NSArray array];
}

- (void) adjustControllerSize:(UIViewController *)controller
{
    if (!controller) return;

    [self updateOrientation];

    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    int x, y;
    int width, height;

    x = 0;
    y = toolbarHeight;

    if (UIInterfaceOrientationIsLandscape(orient)) {
        width = fr1.size.height;
        height = fr1.size.width - toolbarHeight;
    } else if (UIInterfaceOrientationIsPortrait(orient)) {
        width = fr1.size.width;
        height = fr1.size.height - toolbarHeight;
    }

    if (keyboardShown) {
        if (UIDeviceOrientationIsLandscape(orient))
            height -= keyboardSize.width;
        else
            height -= keyboardSize.height;
    }

    if (IS_SPLIT && UIDeviceOrientationIsLandscape(orient)) {
        width -= toolbarHeight;
        height += toolbarHeight;
    }

    NSLog(@"Adjusting controller size %@ TO (%d, %d)", [[controller class] description], width, height);

    controller.view.frame = CGRectMake(x, y, width, height);
    [controller.view setNeedsLayout];

    SEL reloadSelector = @selector(reload);
    if ([controller respondsToSelector:reloadSelector]) [controller performSelector:reloadSelector];
}

- (void) adjustCurrentController
{
    [self adjustControllerSize:currentController];
}

- (void)switchTo:(UIViewController<ContentPaneDelegate> *)controller
{
    // Remove all controls from the toolbar except the popover button.
    if ([[toolbar items] count] > 0) {
        UIBarButtonItem *pb = [[toolbar items] objectAtIndex:0];
        [toolbar setItems:[NSArray arrayWithObjects:pb, nil]];
    } else {
        [toolbar setItems:[NSArray array]];
    }

    // Force the view to load.
    if (![controller isViewLoaded]) {
        [controller loadView];
        [controller viewDidLoad];
    }

    // Adjust the incoming controller's view to match the available size.
    [self adjustControllerSize:controller];

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

// For non-split-view modes, this creates the project button.
- (void) createProjectButton
{
    self.projectButton =
        [[[UIBarButtonItem alloc]
            initWithTitle:@"Project"
            style:UIBarButtonItemStyleBordered
            target:DELEGATE
            action:@selector(switchToList)] autorelease];
}

#pragma mark Rotation support

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self adjustCurrentController];
    [currentController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark Keyboard Listeners

- (void) setKeyboardSize:(NSNotification *)aNotification
{
    // Get the size of the keyboard.
    if (!IS_IPAD && [[[UIDevice currentDevice] systemVersion] floatValue] < 3.2) {
        [self updateOrientation];

        if (UIDeviceOrientationIsLandscape(orient)) {
            keyboardSize.width = 480;
            keyboardSize.height = 140;
        } else {
            keyboardSize.width = 320;
            keyboardSize.height = 216;
        }
    } else {
        NSDictionary* info = [aNotification userInfo];
        CGRect keyboardBounds;
        [[info valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardBounds];
        keyboardSize = keyboardBounds.size;
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    keyboardShown = true;
    [self setKeyboardSize:aNotification];
    [self adjustControllerSize:currentController];
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    keyboardShown = false;
    [self setKeyboardSize:aNotification];
    [self adjustControllerSize:currentController];
}

#pragma mark View lifecycle

- (void) viewDidLoad
{
    keyboardShown = false;
    [self updateOrientation];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self
           selector:@selector(keyboardWasShown:)
               name:UIKeyboardDidShowNotification object:nil];

    [nc addObserver:self
           selector:@selector(keyboardWasHidden:)
               name:UIKeyboardDidHideNotification object:nil];

    [nc addObserver:self
           selector:@selector(adjustCurrentController)
               name:UIDeviceOrientationDidChangeNotification object:nil];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

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
