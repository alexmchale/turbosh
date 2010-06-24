#import <UIKit/UIKit.h>

@class DetailViewController;

@interface RootViewController : UITableViewController <ContentPaneDelegate> {
    DetailViewController *detailViewController;

    NSInteger currentProjectNum;

    NSArray *projects;
    NSArray *files;
    NSArray *tasks;
}

@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;
@property (nonatomic, retain) NSArray *projects;
@property (nonatomic, retain) NSArray *files;
@property (nonatomic, retain) NSArray *tasks;

- (void) reload;

@end
