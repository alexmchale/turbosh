#import <Foundation/Foundation.h>

@interface NSString (monkey)

- (NSData *) decodeBase64;
- (NSString *) stringByConvertingAnsiColor;
- (NSString *) stringByQuotingJavascript;
- (NSString *) stringBySingleQuoting;
- (NSString *) findMd5;
- (NSData *) dataWithAutoEncoding;
- (NSString *) stringByStrippingWhitespace;
- (bool) hasContent;

@end
