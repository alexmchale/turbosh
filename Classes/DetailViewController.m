//
//  DetailViewController.m
//  SwiftCode
//
//  Created by Alex McHale on 3/24/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "DetailViewController.h"
#import "RootViewController.h"
#import "QuartzCore/CAAnimation.h"
#import "QuartzCore/CAMediaTimingFunction.h"

@interface DetailViewController ()
@property (nonatomic, retain) UIPopoverController *popoverController;
@end



@implementation DetailViewController

@synthesize toolbar, popoverController, currentController;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    }
    
    return self;
}

#pragma mark -
#pragma mark Managing the detail item

- (void)switchTo:(UIViewController *)controller
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
    
    // Remove the current view and replace with the new one.
	[currentController.view removeFromSuperview];
	[self.view insertSubview:controller.view atIndex:0];
	
	// Set up an animation for the transition between the views.
	CATransition *animation = [CATransition animation];
	[animation setDuration:0.5];
	[animation setType:kCATransitionFade];
	//[animation setSubtype:kCATransitionFromTop];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	
	[[self.view layer] addAnimation:animation forKey:@"SwitchToView1"];
    
    self.currentController = controller;
     
    [popoverController dismissPopoverAnimated:YES];
}

#pragma mark -
#pragma mark Split view support

- (void) splitViewController:(UISplitViewController*)svc 
      willHideViewController:(UIViewController *)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem
        forPopoverController:(UIPopoverController*)pc {
    
    barButtonItem.title = @"Root List";
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = pc;

}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void) splitViewController:(UISplitViewController*)svc
      willShowViewController:(UIViewController *)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    NSMutableArray *items = [[toolbar items] mutableCopy];
    [items removeObjectAtIndex:0];
    [toolbar setItems:items animated:YES];
    [items release];
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark View lifecycle

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    currentController.view.frame = CGRectMake(0, toolbarHeight, fr1.size.width, fr1.size.height - toolbarHeight);    
}

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
 */

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Memory management

/*
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
*/

- (void)dealloc {
    [popoverController release];
    [toolbar release];
    [currentController release];
    [super dealloc];
}

@end
