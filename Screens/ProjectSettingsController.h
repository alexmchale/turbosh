#import <UIKit/UIKit.h>
#import <Synchronizer.h>

@interface ProjectSettingsController : UIViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ContentPaneDelegate, UIActionSheetDelegate>
{
    UITableView *myTableView;
    Project *proj;

    UITextField *projectName;

    UITextField *sshHost;
    UITextField *sshPort;
    UITextField *sshUser;
    UITextField *sshPass;
    UITextField *sshPath;

    enum SyncState syncState;
    IBOutlet UILabel *syncLabel;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) UITextField *projectName;
@property (nonatomic, retain) UITextField *sshHost;
@property (nonatomic, retain) UITextField *sshPort;
@property (nonatomic, retain) UITextField *sshUser;
@property (nonatomic, retain) UITextField *sshPass;
@property (nonatomic, retain) UITextField *sshPath;
@property (nonatomic, retain) IBOutlet UILabel *syncLabel;

- (void) saveForm;
- (void) setProject:(Project *)newProject;

typedef enum {
    TS_PROJECT_MAIN,
    TS_SSH_CREDENTIALS,
    TS_SUBSCRIPTION,
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
    TS_MANAGE_FILES,
    TS_MANAGE_PATHS,
    TS_MANAGE_TASKS,
    TS_ROW_COUNT
} TableSubscriptions;

typedef enum {
    TAR_ADD_PROJECT,
    TAR_REM_PROJECT,
    TAR_ROW_COUNT
} TableAddRem;

@end
