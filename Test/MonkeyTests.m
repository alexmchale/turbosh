#import "GHUnit.h"

@interface MonkeyTests : GHTestCase { }
@end

@implementation MonkeyTests

- (void) testFail
{
    NSString *s1 = @"My Axe's Wife";
    NSString *s2 = [s1 stringBySingleQuoting];

    GHAssertEqualStrings(s1, s2, @"String should be quoted");
    GHAssertTrue(false, @"Must fail to succeed");
}

@end
