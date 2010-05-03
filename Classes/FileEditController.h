#import <UIKit/UIKit.h>

@interface FileEditController : UIViewController
    <UITextViewDelegate, ContentPaneDelegate>
{
    UITextView *textView;
    NSString *text;
    CGRect startingRect;
    UIToolbar *myToolbar;
    NSArray *savedToolbarItems;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *label;
    UIBarButtonItem *saveButton;
    bool keyboardShown;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) NSString *text;
@property CGRect startingRect;
@property (nonatomic, retain) UIToolbar *myToolbar;
@property (nonatomic, retain) NSArray *savedToolbarItems;

@end
