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
    UIBarButtonItem *projectButton;

    UIViewController<ContentPaneDelegate> *currentController;

    UILabel *label;
    UIActivityIndicatorView *spinner;

    bool keyboardShown;
    CGSize keyboardSize;

    UIDeviceOrientation orient;
}

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) UIBarButtonItem *projectButton;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

- (void) switchTo:(UIViewController<ContentPaneDelegate> *)controller;
- (void) clearToolbar;
- (void) adjustCurrentController;
- (void) createProjectButton;

@end
