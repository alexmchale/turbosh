//
//  DetailViewController.h
//  SwiftCode
//
//  Created by Alex McHale on 3/24/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UIPopoverControllerDelegate, UISplitViewControllerDelegate> {
    
    UIPopoverController *popoverController;
    UIToolbar *toolbar;
    
    SwitchController *switcher;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

@property (nonatomic, retain) IBOutlet SwitchController *switcher;

- (void) switchTo:(UIViewController *)controller;

@end
