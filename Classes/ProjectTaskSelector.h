#import <UIKit/UIKit.h>

@interface ProjectTaskSelector : UITableViewController
    <ContentPaneDelegate, UIAlertViewDelegate>
{
    UITableView *myTableView;

    Project *project;

    NSArray *allFiles;
    NSMutableArray *syncFiles;
    NSMutableArray *removedFiles;

    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *saveButton;

    bool busy;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *allFiles;
@property (nonatomic, retain) NSMutableArray *syncFiles;
@property (nonatomic, retain) NSMutableArray *removedFiles;

@end
