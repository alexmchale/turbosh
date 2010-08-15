#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <Theme.h>

@class Project;
@class ProjectFile;
@class ProjectTask;

@interface Store : NSObject
{
}

+ (void) open;
+ (void) close;

+ (NSArray *) projects;
+ (BOOL) loadProject:(Project *)project;
+ (void) storeProject:(Project *)project;
+ (void) deleteProject:(Project *)project;
+ (NSNumber *) currentProjectNum;
+ (void) setCurrentProject:(Project *)project;
+ (NSInteger) projectCount;
+ (NSNumber *) projectNumAtOffset:(NSInteger)offset;
+ (NSNumber *) projectNumAfterNum:(NSNumber *)num;
+ (bool) projectExists:(NSNumber *)num;

+ (NSNumber *) currentFileNum;
+ (void) setCurrentFile:(ProjectFile *)file;
+ (NSNumber *) projectFileNumber:(Project *)project atOffset:(NSInteger)offset ofUsage:(FileUsage)usage;
+ (NSInteger) fileCountForCurrentProject:(FileUsage)usage;
+ (NSInteger) fileCount:(Project *)project ofUsage:(FileUsage)usage;
+ (NSArray *) filenames:(Project *)project ofUsage:(FileUsage)usage;
+ (NSArray *) files:(Project *)project ofUsage:(FileUsage)usage;
+ (void) deleteProjectFile:(ProjectFile *)file;
+ (BOOL) loadProjectFile:(ProjectFile *)file;
+ (void) storeProjectFile:(ProjectFile *)file;
+ (NSNumber *) projectFileNumber:(Project *)project filename:(NSString *)filename ofUsage:(FileUsage)usage;
+ (NSData *) fileContent:(ProjectFile *)file;
+ (void) storeLocal:(ProjectFile *)file content:(NSData *)content;
+ (void) storeRemote:(ProjectFile *)file content:(NSData *)content;
+ (bool) fileExists:(NSNumber *)num;

+ (void) setFontSize:(NSInteger)size;
+ (NSInteger) fontSize;

+ (void) setTheme:(Theme *)theme;
+ (Theme *) theme;

+ (void) setSplit:(bool)split;
+ (bool) isSplit;

+ (NSString *) contentType:(ProjectFile *)file;
+ (void) setContentType:(NSString *)contentType forFile:(ProjectFile *)file;

+ (void) setValue:(NSString *)value forKey:(NSString *)key;
+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key;

+ (NSString *) stringValue:(NSString *)key;
+ (NSInteger) intValue:(NSString *)key;

+ (void) setColumn:(NSString *)col onTable:(NSString *)tab withValue:(NSString *)val where:(NSString *)where;
+ (NSString *) scalar:(NSString *)col onTable:(NSString *)tab where:(NSString *)where offset:(NSInteger)offset orderBy:(NSString *)order;
+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab;
+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab offset:(NSInteger)offset orderBy:(NSString *)order;
+ (NSInteger) scalarInt:(NSString *)col
                onTable:(NSString *)tab
                  where:(NSString *)where
                 offset:(NSInteger)offset orderBy:(NSString *)order;

@end
