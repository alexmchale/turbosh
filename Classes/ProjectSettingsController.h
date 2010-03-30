#import <UIKit/UIKit.h>

@interface ProjectSettingsController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    Project *proj;
}

@property (nonatomic, retain) Project *proj;

@end
