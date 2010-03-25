#import <UIKit/UIKit.h>

@interface SwitchController : UIViewController
{
    UIViewController *currentController;
}

@property (nonatomic, retain) UIViewController *currentController;

- (void) switchTo:(UIViewController *)controller;

@end
