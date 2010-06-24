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

#define IS_IPHONE      (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define CURRENT_DEVICE ([UIDevice currentDevice])
#define DELEGATE       ((TurboshAppDelegate *)[[UIApplication sharedApplication] delegate])
