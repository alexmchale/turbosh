#import "StringUtil.h"

@implementation NSString (monkey)

- (NSString *) stringByConvertingAnsiColor
{
    const char *rs = [self cStringUsingEncoding:NSUTF8StringEncoding];
    char c;
    bool readingColor = false;
    bool inColor = false;

    NSMutableString *ms = [NSMutableString string];

    while (c = *rs++) {
        if (readingColor) {
        } else {
        }
    }

    if (inColor) [ms appendString:@"</span>"];

    return ms;
}

- (NSString *) stringByQuotingJavascript
{
    NSString *ns = [self stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    return [NSString stringWithFormat:@"'%@'", ns];
}

@end
