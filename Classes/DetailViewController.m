#import "DetailViewController.h"
#import "RootViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CAMediaTimingFunction.h"

@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
@end

@implementation DetailViewController

@synthesize toolbar, popoverController;

#pragma mark Switcher View Manager

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
    [controller viewSwitcher:self configureToolbar:toolbar];

    // View will appear / disappear.
    [controller viewWillAppear:YES];
    [currentController viewWillDisappear:YES];

    // Remove the current view and replace with the new one.
	[currentController.view removeFromSuperview];
	[self.view insertSubview:controller.view atIndex:0];

    // View did appear / disappear.
    [controller viewDidAppear:YES];
    [currentController viewDidDisappear:YES];

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

const NSInteger SPLIT_BUTTON_TAG = 91218;

- (void) splitViewController:(UISplitViewController*)svc
      willHideViewController:(UIViewController *)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem
        forPopoverController:(UIPopoverController*)pc
{
    barButtonItem.title = @"Project";
    barButtonItem.tag = SPLIT_BUTTON_TAG;

    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void) splitViewController:(UISplitViewController*)svc
      willShowViewController:(UIViewController *)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [[toolbar items] mutableCopy];

    id firstItem = [items objectAtIndex:0];
    if ([firstItem isKindOfClass:[UIBarButtonItem class]] && [firstItem tag] == SPLIT_BUTTON_TAG)
        [items removeObjectAtIndex:0];

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

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    CGRect fr2 = CGRectMake(0, toolbarHeight, fr1.size.width, fr1.size.height - toolbarHeight);
    currentController.view.frame = fr2;
}

- (void)viewDidUnload {
    self.popoverController = nil;
    self.toolbar = nil;
}

#pragma mark Memory management

- (void)dealloc {
    [popoverController release];
    [toolbar release];
    [currentController release];

    [super dealloc];
}

@end
