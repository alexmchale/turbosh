#import <UIKit/UIKit.h>

@interface TaskExecController : UIViewController
{
    UIWebView *webView;

    CommandDispatcher *dispatcher;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) CommandDispatcher *dispatcher;

@end
