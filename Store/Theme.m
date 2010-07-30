#import "Theme.h"

static const ThemeSettings themeSettings[] = {
    { @"navy", @"Blue", { 0.0, 0.0, 1.0 }, { 0.0, 0.0, 0.0 } }
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

static Theme *buildThemeObject(int index)
{
    assert(index >= 0);
    assert(index < sizeof(themeSettings)/sizeof(ThemeSettings));

    const ThemeSettings *settings = &themeSettings[index];

    float fgRed = settings->fgColor.r;
    float fgGreen = settings->fgColor.g;
    float fgBlue = settings->fgColor.b;

    float bgRed = settings->bgColor.r;
    float bgGreen = settings->bgColor.g;
    float bgBlue = settings->bgColor.b;

    Theme *theme = [[[Theme alloc] init] autorelease];

    theme.shjsName = settings->shjsName;
    theme.turboshName = settings->turboshName;
    theme.fgColor = [UIColor colorWithRed:fgRed green:fgGreen blue:fgBlue alpha:1.0];
    theme.bgColor = [UIColor colorWithRed:bgRed green:bgGreen blue:bgBlue alpha:1.0];

    return theme;
}


@implementation Theme

@synthesize shjsName, turboshName, bgColor, fgColor;

+ (Theme *) named:(NSString *)name
{
    int themeCount = sizeof(themeSettings) / sizeof(ThemeSettings);
    int themeIndex = 0;

    for (int i = 0; i < themeCount; ++i) {
        if ([themeSettings[i].turboshName isEqualToString:name]) themeIndex = i;
    }

    return buildThemeObject(themeIndex);
}

@end
