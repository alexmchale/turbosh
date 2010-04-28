#import "StringUtil.h"

@implementation NSString (monkey)

- (NSString *) stringByConvertingAnsiColor
{
    const char *rs = [self cStringUsingEncoding:NSUTF8StringEncoding];
    char c;
    bool inColor = false;

    AnsiCode *ansi = [[AnsiCode alloc] init];
    NSMutableString *ms = [NSMutableString string];

    while (c = *rs++) {
        if (c == 27) {
            [ansi start];

            while (c = *++rs && [ansi append:c])
                continue;

            if (inColor) [ms appendFormat:@"</span>"];
            inColor = true;
            [ms appendFormat:@"<span class='%@'>", [ansi cssName]];
        } else {
            [ms appendFormat:@"%c", c];
        }
    }

    if (inColor) [ms appendString:@"</span>"];

    [ansi release];

    return ms;
}

- (NSString *) stringByQuotingJavascript
{
    NSString *ns = [self stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    return [NSString stringWithFormat:@"'%@'", ns];
}

@end
