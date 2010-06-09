#import "DataUtil.h"

@implementation NSData (nsdata_monkey)

- (NSString *) stringWithAutoEncoding
{
    NSString *s = nil;

    s = [[NSString alloc] initWithData:self encoding:NSASCIIStringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF16StringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF32StringEncoding];
    if (s != nil) return [s autorelease];

    return nil;
}

@end
