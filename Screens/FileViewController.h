#import <UIKit/UIKit.h>
#import <FontPicker.h>

@interface FileViewController : UIViewController
    <UIWebViewDelegate, ContentPaneDelegate, FontPickerDelegate>
{
    UIWebView *webView;
    ProjectFile *file;
    CGRect startingRect;

    FontPickerController *_fontPicker;
    id _fontPickerPopover;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ProjectFile *file;
@property CGRect startingRect;
@property (nonatomic, retain) FontPickerController *fontPicker;
@property (nonatomic, retain) id fontPickerPopover;

@end
