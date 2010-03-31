#import <UIKit/UIKit.h>

@interface ProjectSettingsController : UIViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    Project *proj;
	
	UITextField *projectName;
	
	UITextField *sshHost;
	UITextField *sshPort;
	UITextField *sshUser;
	UITextField *sshPass;
	UITextField *sshPath;
}

@property (nonatomic, retain) Project *proj;

@property (nonatomic, retain) UITextField *projectName;

@property (nonatomic, retain) UITextField *sshHost;
@property (nonatomic, retain) UITextField *sshPort;
@property (nonatomic, retain) UITextField *sshUser;
@property (nonatomic, retain) UITextField *sshPass;
@property (nonatomic, retain) UITextField *sshPath;

@end
