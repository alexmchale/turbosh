#import <Foundation/Foundation.h>

@interface NSData (nsdata_monkey)

- (NSString *) stringWithAutoEncoding;
- (NSString *) base64;

- (NSString *) encodeBase64WithNewlines: (BOOL) encodeWithNewlines;

@end
