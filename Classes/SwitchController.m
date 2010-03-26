    //
//  SwitchController.m
//  SwiftCode
//
//  Created by Alex McHale on 3/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SwitchController.h"


@implementation SwitchController

@synthesize currentController;

- (void) switchTo:(UIViewController *)controller
{
    NSUInteger toolbarIndex = currentController ? 1 : 0;
    UIToolbar *toolbar = [self.view.subviews objectAtIndex:toolbarIndex];
    NSInteger toolbarHeight = toolbar.frame.size.height;
    CGRect fr1 = self.view.frame;
    controller.view.frame = CGRectMake(0, toolbarHeight, fr1.size.width, fr1.size.height - toolbarHeight);

    [UIView beginAnimations:@"View Flip" context:nil];
    [UIView setAnimationDuration:1.25];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                           forView:self.view
                             cache:NO];
    
    [controller viewWillAppear:YES];
    [currentController viewWillDisappear:YES];
    [currentController.view removeFromSuperview];    
    [self.view insertSubview:controller.view atIndex:0];
    [currentController viewDidDisappear:YES];
    [controller viewDidAppear:YES];
    
    //[UIView commitAnimations];
    
    self.currentController = controller;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


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
