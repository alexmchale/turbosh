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
    UIBarItem *projectButton;

    UIViewController<ContentPaneDelegate> *currentController;

    UILabel *label;
    UIActivityIndicatorView *spinner;

    bool keyboardShown;
    CGSize keyboardSize;
}

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) UIBarItem *projectButton;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

- (void) switchTo:(UIViewController<ContentPaneDelegate> *)controller;
- (void) clearToolbar;
- (void) adjustCurrentController;

@end
