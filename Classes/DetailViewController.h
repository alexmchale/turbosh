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
    UIActivityIndicatorView *spinner;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

- (void) switchTo:(UIViewController *)controller;

@end
