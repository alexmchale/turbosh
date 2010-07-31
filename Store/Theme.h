#import <Foundation/Foundation.h>

typedef struct {
    float r;
    float g;
    float b;
} SimpleColor;

typedef struct {
    NSString *turboshName;
    NSString *shjsName;
    SimpleColor bgColor;
    SimpleColor fgColor;
} ThemeSettings;

@interface Theme : NSObject
{
}

+ (Theme *) themeWithShjsName:(NSString *)name;
+ (NSArray *) all;
+ (Theme *) current;

@property (nonatomic, retain) NSString *turboshName;
@property (nonatomic, retain) NSString *shjsName;
@property (nonatomic, retain) UIColor *bgColor;
@property (nonatomic, retain) UIColor *fgColor;

@end
