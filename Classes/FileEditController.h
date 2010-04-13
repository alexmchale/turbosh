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
    UIBarButtonItem *saveButton;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) NSString *text;
@property CGRect startingRect;
@property (nonatomic, retain) UIToolbar *myToolbar;
@property (nonatomic, retain) NSArray *savedToolbarItems;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;
@property (nonatomic, retain) UIBarButtonItem *spacer;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end
