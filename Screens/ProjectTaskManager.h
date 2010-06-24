#import <UIKit/UIKit.h>

enum
{
    PTM_COMMAND,
    PTM_PARAMETERS,
    PTM_ROW_COUNT
};

@interface ProjectTaskManager : UITableViewController <ContentPaneDelegate>
{
    Project *project;
    NSArray *files;
    NSArray *cmdFields;
    NSArray *argFields;
}

@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *files;
@property (nonatomic, retain) NSArray *cmdFields;
@property (nonatomic, retain) NSArray *argFields;

@end
