#import <Foundation/Foundation.h>
#import "Project.h"

@class Project;

@interface ProjectFile : NSObject
{
    NSNumber *num;
    Project *project;

    NSString *filename;
    NSString *remoteMd5;
    NSString *localMd5;
}

@property (nonatomic, retain) NSNumber *num;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *remoteMd5;
@property (nonatomic, retain) NSString *localMd5;

- (id) loadByNumber:(NSNumber *)number;
- (id) loadByProject:(Project *)myProject filename:(NSString *)myFilename;

- (NSString *)content;
- (NSString *)contentType;
- (NSString *)fullpath;
- (NSString *)escapedPath;
- (NSString *)escapedRelativePath;
- (NSString *)condensedPath;
- (NSString *)extension;
- (bool) existsInDatabase;

@end