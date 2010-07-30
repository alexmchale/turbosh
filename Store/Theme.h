#import <Foundation/Foundation.h>

typedef struct {
    float r;
    float g;
    float b;
} SimpleColor;

typedef struct {
    NSString *shjsName;
    NSString *turboshName;
    SimpleColor bgColor;
    SimpleColor fgColor;
} ThemeSettings;

@interface Theme : NSObject
{
}

+ (Theme *) named:(NSString *)name;

@property (nonatomic, retain) NSString *shjsName;
@property (nonatomic, retain) NSString *turboshName;
@property (nonatomic, retain) UIColor *bgColor;
@property (nonatomic, retain) UIColor *fgColor;

@end
