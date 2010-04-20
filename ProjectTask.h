#import <Foundation/Foundation.h>

@interface ProjectTask : NSObject
{
    NSNumber *num;
    Project *project;

    NSString *name;
    NSString *script;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *script;

- (id) initAsNumber:(NSNumber *)newNum;
- (id) initAsNumber:(NSNumber *)newNum forProject:(Project *)myProject;

@end
