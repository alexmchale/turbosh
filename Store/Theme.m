#import "Theme.h"

@implementation Theme

@synthesize shjsName, turboshName, bgColor, fgColor;

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

static const int themeCount = sizeof(themeSettings) / sizeof(ThemeSettings);

static NSMutableArray *themes = nil;

static Theme *buildThemeObject(NSUInteger index)
{
    assert(index < themeCount);

    const ThemeSettings *settings = &themeSettings[index % themeCount];

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

+ (Theme *) themeWithShjsName:(NSString *)name
{
    int themeIndex = 0;

    for (int i = 0; i < themeCount; ++i) {
        if ([themeSettings[i].shjsName isEqualToString:name]) themeIndex = i;
    }

    return buildThemeObject(themeIndex);
}

+ (NSArray *) all
{
    if (!themes) {
        themes = [[NSMutableArray alloc] init];

        for (int i = 0; i < themeCount; ++i) {
            [themes addObject:buildThemeObject(i)];
        }
    }

    return themes;
}

+ (Theme *) current
{
    return [Store theme];
}

@end
