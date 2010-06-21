#import <UIKit/UIKit.h>

@interface TextFieldCell : UITableViewCell
{
    UILabel *label;
    UITextField *text;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UITextField *text;

+ (id) cellForTableView:(UITableView *)tableView;
+ (id) cellForTableView:(UITableView *)tableView labeled:(NSString *)name;

- (void) adjustSizeFor:(UITableView *)tableView;
- (NSString *) value;
- (void) setValue:(NSString *)value;

@end
