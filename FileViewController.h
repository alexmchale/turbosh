#import <UIKit/UIKit.h>
#import "ProjectFile.h"

@interface FileViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView *webView;
    ProjectFile *file;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ProjectFile *file;

@end
