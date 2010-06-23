#import <UIKit/UIKit.h>

@interface ProjectFileSelector : UIViewController
    <ContentPaneDelegate, UIAlertViewDelegate, UISearchBarDelegate>
{
    UITableView *myTableView;

    Project *project;

    NSArray *allFiles;
    NSArray *shownFiles;
    NSMutableArray *syncFiles;
    NSMutableArray *removedFiles;

    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *saveButton;

    bool busy;
    FileUsage mode;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *allFiles;
@property (nonatomic, retain) NSArray *shownFiles;
@property (nonatomic, retain) NSMutableArray *syncFiles;
@property (nonatomic, retain) NSMutableArray *removedFiles;
@property FileUsage mode;

@end
