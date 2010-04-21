#import <UIKit/UIKit.h>

@interface ProjectSettingsController : UIViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ContentPaneDelegate>
{
    UITableView IBOutlet *myTableView;
    Project *proj;

    UITextField *projectName;

    UITextField *sshHost;
    UITextField *sshPort;
    UITextField *sshUser;
    UITextField *sshPass;
    UITextField *sshPath;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;

@property (nonatomic, retain) Project *proj;

@property (nonatomic, retain) UITextField *projectName;

@property (nonatomic, retain) UITextField *sshHost;
@property (nonatomic, retain) UITextField *sshPort;
@property (nonatomic, retain) UITextField *sshUser;
@property (nonatomic, retain) UITextField *sshPass;
@property (nonatomic, retain) UITextField *sshPath;

typedef enum {
    TS_PROJECT_MAIN,
    TS_SSH_CREDENTIALS,
    TS_FILES,
    TS_ADD_REM,
    TS_SECTION_COUNT
} TableSections;

typedef enum {
    TM_NAME,
    TM_ROW_COUNT
} TableMain;

typedef enum {
    TC_HOSTNAME,
    TC_PORT,
    TC_USERNAME,
    TC_PASSWORD,
    TC_PATH,
    TC_ROW_COUNT
} TableCredentials;

typedef enum {
    TF_MANAGE,
    TF_ROW_COUNT
} TableFiles;

typedef enum {
    TAR_ADD_PROJECT,
    TAR_REM_PROJECT,
    TAR_ROW_COUNT
} TableAddRem;

@end
