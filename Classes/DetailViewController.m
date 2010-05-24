#import "DetailViewController.h"
#import "RootViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CAMediaTimingFunction.h"

@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
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

- (void)switchTo:(UIViewController<ContentPaneDelegate> *)controller
{
    // Adjust the incoming controller's view to match the available size.
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    controller.view.frame = CGRectMake(0, toolbarHeight, fr1.size.width, fr1.size.height - toolbarHeight);

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

#pragma mark View lifecycle

- (void) viewDidLoad
{
    projectButton = nil;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    CGRect fr2 = CGRectMake(0, toolbarHeight, fr1.size.width, fr1.size.height - toolbarHeight);
    currentController.view.frame = fr2;
}

- (void)viewDidUnload {
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
