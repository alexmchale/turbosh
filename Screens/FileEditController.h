#import <UIKit/UIKit.h>

@interface FileEditController : UIViewController
    <UITextViewDelegate, ContentPaneDelegate>
{
    UITextView *textView;
    NSString *text;
    CGRect startingRect;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *saveButton;
    bool keyboardShown;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) NSString *text;
@property CGRect startingRect;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;
@property (nonatomic, retain) UIBarButtonItem *spacer;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end
