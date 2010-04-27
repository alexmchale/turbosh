#import <UIKit/UIKit.h>

@interface TaskExecController : UIViewController
{
    UIWebView *webView;

    CommandDispatcher *dispatcher;
    NSTimer *timer;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) CommandDispatcher *dispatcher;
@property (nonatomic, retain) NSTimer *timer;

@end
