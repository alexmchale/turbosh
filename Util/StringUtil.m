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

            do {
                rs++;
                c = *rs;
            } while (c && [ansi append:c]);

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
    ns = [ns stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    return [NSString stringWithFormat:@"'%@'", ns];
}

- (NSString *) stringBySingleQuoting
{
    NSString *ns = [self stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    return [NSString stringWithFormat:@"'%@'", ns];
}

- (NSString *) findMd5
{
    NSString *r1 = @"MD5 .* = ([0-9A-F]{32})$"; // BSD-style MD5 result.
    NSString *r2 = @"^([0-9A-F]{32}) ";         // Linux-style MD5 result.
    NSString *r3 = @"([0-9A-F]{32})";           // Generic MD5 result.

    NSArray *md5Regexes = [NSArray arrayWithObjects:r1, r2, r3, nil];
    NSString *upper = [self uppercaseString];

    for (NSString *regex in md5Regexes) {
        NSArray *comps = [upper componentsMatchedByRegex:regex capture:1];

        if ([comps count] > 0) return [comps objectAtIndex:0];
    }

    return nil;
}

@end
