#import <Foundation/Foundation.h>

NSString *hex_md5(NSData *str);
void show_alert(NSString *title, NSString *message);
void show_action_sheet(UIViewController *con, int tag, NSString *msg, NSString *no, NSString *yes);

@interface Utils : NSObject
{
}

@end
