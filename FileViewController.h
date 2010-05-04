#import <UIKit/UIKit.h>
#import "ProjectFile.h"

@interface FileViewController : UIViewController <UIWebViewDelegate, ContentPaneDelegate>
{
    UIWebView *webView;
    ProjectFile *file;
    CGRect startingRect;

    UIToolbar *myToolbar;
    NSArray *savedToolbar;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) ProjectFile *file;
@property CGRect startingRect;
@property (nonatomic, retain) UIToolbar *myToolbar;
@property (nonatomic, retain) NSArray *savedToolbar;

@end
