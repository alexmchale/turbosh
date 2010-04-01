#import <UIKit/UIKit.h>

@interface ProjectFileSelector : UITableViewController <ContentPaneDelegate>
{
    UITableView *myTableView;
    
    Project *project;
    
    NSArray *allFiles;
    NSMutableArray *syncFiles;
    
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *spacer;
    UIBarButtonItem *saveButton;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *allFiles;
@property (nonatomic, retain) NSMutableArray *syncFiles;
@property (nonatomic, retain) UIBarButtonItem *cancelButton;
@property (nonatomic, retain) UIBarButtonItem *spacer;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end
