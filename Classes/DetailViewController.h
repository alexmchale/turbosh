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

    UILabel *label;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *label;

- (void) switchTo:(UIViewController *)controller;

@end
