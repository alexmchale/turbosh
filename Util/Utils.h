#import <Foundation/Foundation.h>

NSString *hex_md5(NSData *str);
void show_alert(NSString *title, NSString *message);

@interface Utils : NSObject
{
}

+ (NSString *) getUrl:(NSURL *)url;

@end
