#import <UIKit/UIKit.h>
#import <Synchronizer.h>

@interface ProjectSettingsController : UIViewController
	<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,
     ContentPaneDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    UITableView *myTableView;
    Project *proj;

    TextFieldCell *projectName;

    TextFieldCell *sshHost;
    TextFieldCell *sshPort;
    TextFieldCell *sshUser;
    TextFieldCell *sshPass;
    TextFieldCell *sshPath;

    enum SyncState syncState;
    IBOutlet UILabel *syncLabel;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) TextFieldCell *projectName;
@property (nonatomic, retain) TextFieldCell *sshHost;
@property (nonatomic, retain) TextFieldCell *sshPort;
@property (nonatomic, retain) TextFieldCell *sshUser;
@property (nonatomic, retain) TextFieldCell *sshPass;
@property (nonatomic, retain) TextFieldCell *sshPath;
@property (nonatomic, retain) IBOutlet UILabel *syncLabel;

- (void) saveForm;
- (void) setProject:(Project *)newProject;

typedef enum {
    TS_PROJECT_MAIN,
    TS_SSH_CREDENTIALS,
    TS_SUBSCRIPTION,
    TS_ADD_REM,
    TS_MANAGE_KEY,
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
    TPK_CLIPBOARD_KEY,
    TPK_SEND_KEY,
    TPK_RESET_KEY,
    TPK_ROW_COUNT
} TablePublicKey;

typedef enum {
    TAR_ADD_PROJECT,
    TAR_REM_PROJECT,
    TAR_ROW_COUNT
} TableAddRem;

@end
