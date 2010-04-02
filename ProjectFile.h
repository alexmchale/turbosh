#import <Foundation/Foundation.h>
#import "Project.h"

@class Project;

@interface ProjectFile : NSObject
{
    NSNumber *num;
    Project *project;
    NSString *filename;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSString *filename;

- (ProjectFile *)initByNumber:(NSNumber *)number;
- (id) initByProject:(Project *)myProject filename:(NSString *)myFilename;
- (NSString *)content;

@end
