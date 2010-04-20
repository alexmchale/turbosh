#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class Project;
@class ProjectFile;
@class ProjectTask;

@interface Store : NSObject
{
}

+ (void) open;
+ (void) close;

+ (BOOL) loadProject:(Project *)project;
+ (void) storeProject:(Project *)project;
+ (NSNumber *) currentProjectNum;
+ (void) setCurrentProject:(Project *)project;
+ (NSInteger) projectCount;
+ (NSNumber *) projectNumAtOffset:(NSInteger)offset;
+ (NSNumber *) projectNumAfterNum:(NSNumber *)num;

+ (NSNumber *) currentFileNum;
+ (void) setCurrentFile:(ProjectFile *)file;
+ (NSNumber *) projectFileNumber:(Project *)project atOffset:(NSInteger)offset;
+ (NSInteger) fileCountForCurrentProject;
+ (NSInteger) fileCount:(Project *)project;
+ (NSArray *) filenames:(Project *)project;
+ (void) deleteProjectFile:(ProjectFile *)file;
+ (BOOL) loadProjectFile:(ProjectFile *)file;
+ (void) storeProjectFile:(ProjectFile *)file;
+ (NSNumber *) projectFileNumber:(Project *)project filename:(NSString *)filename;
+ (NSString *) fileContent:(ProjectFile *)file;
+ (void) storeLocal:(ProjectFile *)file content:(NSData *)content;
+ (void) storeRemote:(ProjectFile *)file content:(NSData *)content;

+ (bool) loadTask:(ProjectTask *)task;
+ (void) storeTask:(ProjectTask *)task;

+ (void) setValue:(NSString *)value forKey:(NSString *)key;
+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key;

+ (NSString *) stringValue:(NSString *)key;
+ (NSInteger) intValue:(NSString *)key;

+ (NSString *) scalar:(NSString *)col onTable:(NSString *)tab where:(NSString *)where offset:(NSInteger)offset orderBy:(NSString *)order;
+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab;
+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab offset:(NSInteger)offset orderBy:(NSString *)order;
+ (NSInteger) scalarInt:(NSString *)col
                onTable:(NSString *)tab
                  where:(NSString *)where
                 offset:(NSInteger)offset orderBy:(NSString *)order;

@end
