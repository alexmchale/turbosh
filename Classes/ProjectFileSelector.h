#import <UIKit/UIKit.h>

@interface ProjectFileSelector : UITableViewController
    <ContentPaneDelegate, UIAlertViewDelegate>
{
    UITableView *myTableView;
    UIToolbar *myToolbar;
    NSArray *savedToolbarItems;
    
    Project *project;
    
    NSArray *allFiles;
    NSMutableArray *syncFiles;
    NSMutableArray *removedFiles;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *saveButton;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) UIToolbar *myToolbar;
@property (nonatomic, retain) NSArray *savedToolbarItems;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *allFiles;
@property (nonatomic, retain) NSMutableArray *syncFiles;
@property (nonatomic, retain) NSMutableArray *removedFiles;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;
@property (nonatomic, retain) UIBarButtonItem *spacer;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end
