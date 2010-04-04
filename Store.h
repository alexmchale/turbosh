#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class Project;
@class ProjectFile;

@interface Store : NSObject 
{
}

+ (void) open;
+ (void) close;

+ (BOOL) loadProject:(Project *)project;
+ (void) storeProject:(Project *)project;
+ (Project *) currentProject;
+ (void) setCurrentProject:(Project *)project;
+ (Project *) findProjectByNum:(NSInteger)num;
+ (NSInteger) projectCount;
+ (Project *) projectAtOffset:(NSInteger)offset;

+ (NSInteger) fileCount:(Project *)project;
+ (NSArray *) filenames:(Project *)project;
+ (void) deleteProjectFile:(ProjectFile *)file;
+ (BOOL) loadProjectFile:(ProjectFile *)file;
+ (void) storeProjectFile:(ProjectFile *)file;
+ (NSNumber *) projectFileNumber:(Project *)project filename:(NSString *)filename;
+ (ProjectFile *) projectFile:(Project *)project filename:(NSString *)filename;
+ (ProjectFile *) projectFile:(Project *)project atOffset:(NSInteger)offset;
+ (void) storeLocal:(ProjectFile *)file content:(NSData *)content;
+ (void) storeRemote:(ProjectFile *)file content:(NSData *)content;

+ (void) setValue:(NSString *)value forKey:(NSString *)key;
+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key;

+ (NSString *) stringValue:(NSString *)key;
+ (NSInteger) intValue:(NSString *)key;

+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab;
+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab offset:(NSInteger)offset orderBy:(NSString *)order;
+ (NSInteger) scalarInt:(NSString *)col
                onTable:(NSString *)tab
                  where:(NSString *)where
                 offset:(NSInteger)offset orderBy:(NSString *)order;

@end
