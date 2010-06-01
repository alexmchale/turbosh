#import <Foundation/Foundation.h>

@interface AnsiCode : NSObject
{
    bool bold;
    NSMutableArray *codes;
    int nextValue;
    bool completed;
}

- (void) start;
- (bool) append:(char)c;
- (NSString *) cssName;

@end
