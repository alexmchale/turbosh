#import "Theme.h"

static const ThemeSettings themeSettings[] = {
    { @"Blue",    @"navy",       { 0.000, 0.000, 0.207 }, { 0.000, 0.545, 1.000 } },
    { @"Dark 1",  @"darkness",   { 0.000, 0.000, 0.000 }, { 1.000, 1.000, 1.000 } },
    { @"Dark 2",  @"neon",       { 0.000, 0.000, 0.000 }, { 1.000, 1.000, 1.000 } },
    { @"Dark 3",  @"pablo",      { 0.000, 0.000, 0.000 }, { 1.000, 1.000, 1.000 } },
    { @"Dark 4",  @"vim-dark",   { 0.000, 0.000, 0.000 }, { 1.000, 1.000, 1.000 } },
    { @"Dark 5",  @"whatis",     { 0.000, 0.000, 0.000 }, { 1.000, 1.000, 1.000 } },
    { @"Light 1", @"emacs",      { 1.000, 1.000, 1.000 }, { 0.000, 0.000, 0.000 } },
    { @"Light 2", @"ide-msvcpp", { 1.000, 1.000, 1.000 }, { 0.000, 0.000, 0.000 } },
    { @"Light 3", @"print",      { 1.000, 1.000, 1.000 }, { 0.000, 0.000, 0.000 } },
    { @"Light 4", @"vim",        { 1.000, 1.000, 1.000 }, { 0.000, 0.000, 0.000 } },
    { @"Light 5", @"zellner",    { 1.000, 1.000, 1.000 }, { 0.000, 0.000, 0.000 } },
    { @"Light 6", @"peachpuff",  { 1.000, 0.854, 0.725 }, { 0.000, 0.000, 0.000 } },
    { @"Light 7", @"dull",       { 0.749, 0.749, 0.749 }, { 0.396, 0.396, 0.396 } }
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
