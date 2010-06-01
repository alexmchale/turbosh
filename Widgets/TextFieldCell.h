#import <UIKit/UIKit.h>

@interface TextFieldCell : UITableViewCell
{
    UITextField *text;
}

@property (nonatomic, retain) IBOutlet UITextField *text;

+ (id) cellForTableView:(UITableView *)tableView;
+ (id) cellForTableView:(UITableView *)tableView labeled:(NSString *)name;

@end
