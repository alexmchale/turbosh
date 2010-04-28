#import "StringUtil.h"

@implementation NSString (monkey)

NSString *color_name(int code)
{
    return @"ansiRed";
}

- (NSString *) stringByConvertingAnsiColor
{
    const char *rs = [self cStringUsingEncoding:NSUTF8StringEncoding];
    char c;
    bool inColor = false;
    int code = 0;
    enum { NORM, OPENTAG, CODE } state;

    NSMutableString *ms = [NSMutableString string];

    while (c = *rs++) {
        switch (state) {
            case NORM:
                if (c != 27) {
                    [ms appendFormat:@"%c", c];
                } else {
                    state = OPENTAG;
                }
                break;

            case OPENTAG:
                if (c == '[') {
                    state = CODE;
                    code = 0;
                }
                break;

            case CODE:
                if (c == 'm') {
                    state = NORM;
                    if (inColor) [ms appendFormat:@"</span>"];
                    [ms appendFormat:@"<span class='%@'>", color_name(code)];
                    inColor = true;
                } else {
                    code *= 10;
                    code += c - '0';
                }
                break;
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
