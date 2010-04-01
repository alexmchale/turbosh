#import <UIKit/UIKit.h>

@class DetailViewController;

@protocol ContentPaneDelegate
- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar;
@end

@interface DetailViewController : UIViewController
        <UIPopoverControllerDelegate, UISplitViewControllerDelegate>
{
    
    UIPopoverController *popoverController;
    UIToolbar *toolbar;
    
    UIViewController<ContentPaneDelegate> *currentController;
    
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;

- (void) switchTo:(UIViewController *)controller;

@end
