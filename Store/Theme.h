#import <Foundation/Foundation.h>

@interface Theme : NSObject
{
}

+ (Theme *) named:(NSString *)name;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) UIColor *bgColor;
@property (nonatomic, retain) UIColor *fgColor;

@end
