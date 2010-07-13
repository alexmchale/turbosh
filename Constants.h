enum TagNumbers
{
    TAG_FIRST = 10101,

    TAG_DELETE_PROJECT,
    TAG_FILE_CONFLICT,
    TAG_FILE_MISSING,
    TAG_PROJECT_BUTTON,
    TAG_MD5_COMMAND_MISSING,
    TAG_RESET_KEY
};

typedef enum {
    FU_FILE,
    FU_TASK,
    FU_PATH
} FileUsage;

enum ErrorCodes {
    T_ERR_FILE_TRANSFER_NO_CONTENT = 9000
};

#define IS_IPHONE      (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_SPLIT       (IS_IPAD && [Store isSplit])
#define CURRENT_DEVICE ([UIDevice currentDevice])
#define DELEGATE       ((TurboshAppDelegate *)[[UIApplication sharedApplication] delegate])
#define MASTER_CON     (IS_SPLIT ? DELEGATE.splitViewController : DELEGATE.detailViewController)

#define CHECKMARK(v)   ((v) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone)
