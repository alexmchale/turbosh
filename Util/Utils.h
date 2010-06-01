#import <Foundation/Foundation.h>

NSString *hex_md5(NSData *str);

@interface Utils : NSObject 
{
}

+ (NSString *) getUrl:(NSURL *)url;

@end