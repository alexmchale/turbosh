#import "Theme.h"

typedef enum {
    NSString *shjsName;
    NSString *turboshName;
    UIColor *bgColor;
    UIColor *fgColor;
} ThemeSettings;

ThemeSettings themeSettings[] = {
    {   @"navy",
        @"Blue",
        [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0],
        [UIColor colorWithRed:
};

static NSString *shjsThemes[] = {
    @"navy",
    @"darkness",
    @"neon",
    @"pablo",
    @"vim-dark",
    @"whatis",
    @"emacs",
    @"ide-msvcpp",
    @"print",
    @"vim",
    @"zellner",
    @"peachpuff",
    @"dull"
};

static NSString *turboshThemes[] = {
    @"Blue",
    @"Dark 1",
    @"Dark 2",
    @"Dark 3",
    @"Dark 4",
    @"Dark 5",
    @"Light 1",
    @"Light 2",
    @"Light 3",
    @"Light 4",
    @"Light 5",
    @"Light 6"
};

static UIColor *bgColors[] = {
};

static UIColor *fgColors[] = {
};



@implementation Theme

@synthesize name, bgColor, fgColor;

+ (Theme *) named:(NSString *)name
{
}

@end
