#import <UIKit/UIKit.h>

@interface FileViewController : UIViewController <UIWebViewDelegate, ContentPaneDelegate>
{
    UIWebView *webView;
    ProjectFile *file;
    CGRect startingRect;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ProjectFile *file;
@property CGRect startingRect;

@end
