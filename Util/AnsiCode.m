#import "AnsiCode.h"

@implementation AnsiCode

- (void) start
{
    [codes removeAllObjects];
    bold = false;
    nextValue = 0;
    completed = false;
}

// Return true if the user should continue feeding characters.
- (bool) append:(char)c
{
    // Check if we already hit an endpoint.
    if (completed) return false;

    // Header characters.  Just continue.
    if (c == 27 || c == '[') return true;

    // Break characters.  Set the currently read values.
    if (c == ';' || c == 'm') {
        if (nextValue == 1)
            bold = true;
        else
            [codes addObject:[NSNumber numberWithInt:nextValue]];

        nextValue = 0;
        completed = c == 'm';

        return true;
    }

    // This character is the end of the ANSI color code.
    if (!isdigit(c)) return false;

    nextValue *= 10;
    nextValue += c - '0';

    return true;
}

// Return the calculated CSS class name.
- (NSString *) cssName
{
    NSMutableString *name = [NSMutableString string];

    for (NSNumber *num in codes) {
        switch ([num intValue]) {
            case 4: [name appendString:@"ansiUnderline"]; break;
            case 5: [name appendString:@"ansiBlink"]; break;
            case 7: [name appendString:@"ansiReverse"]; break;
            case 8: [name appendString:@"ansiInvisible"]; break;

            case 30: [name appendString:(bold ? @"ansiBrightBlack" : @"ansiBlack")]; break;
            case 31: [name appendString:(bold ? @"ansiBrightRed" : @"ansiRed")]; break;
            case 32: [name appendString:(bold ? @"ansiBrightGreen" : @"ansiGreen")]; break;
            case 33: [name appendString:(bold ? @"ansiBrightYellow" : @"ansiYellow")]; break;
            case 34: [name appendString:(bold ? @"ansiBrightBlue" : @"ansiBlue")]; break;
            case 35: [name appendString:(bold ? @"ansiBrightMagenta" : @"ansiMagenta")]; break;
            case 36: [name appendString:(bold ? @"ansiBrightCyan" : @"ansiCyan")]; break;
            case 37: [name appendString:(bold ? @"ansiBrightWhite" : @"ansiWhite")]; break;

            case 40: [name appendString:@"ansiBackgroundBlack"]; break;
            case 41: [name appendString:@"ansiBackgroundRed"]; break;
            case 42: [name appendString:@"ansiBackgroundGreen"]; break;
            case 43: [name appendString:@"ansiBackgroundYellow"]; break;
            case 44: [name appendString:@"ansiBackgroundBlue"]; break;
            case 45: [name appendString:@"ansiBackgroundMagenta"]; break;
            case 46: [name appendString:@"ansiBackgroundCyan"]; break;
            case 47: [name appendString:@"ansiBackgroundWhite"]; break;
        }

        [name appendString:@" "];
    }

    return name;
}

#pragma mark Memory Management

- (id) init
{
    self = [super init];

    codes = [[NSMutableArray alloc] init];

    return self;
}

- (void) dealloc
{
    [codes release];

    [super dealloc];
}

@end
