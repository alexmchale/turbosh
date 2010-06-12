#import <Foundation/Foundation.h>

@interface NSString (monkey)

- (NSString *) stringByConvertingAnsiColor;
- (NSString *) stringByQuotingJavascript;
- (NSString *) stringBySingleQuoting;
- (NSString *) findMd5;
- (NSData *) dataWithAutoEncoding;
- (NSString *) stringByStrippingWhitespace;
- (bool) hasContent;

@end
