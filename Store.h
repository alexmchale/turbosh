#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface Store : NSObject 
{
}

+ (void) open;
+ (void) close;

+ (void) setValue:(NSString *)value forKey:(NSString *)key;
+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key;
+ (void) setList:(NSArray *)values forKey:(NSString *)key;
+ (void) insertSetValue:(NSString *)value forKey:(NSString *)key;
+ (void) removeListValue:(NSString *)value forKey:(NSString *)key;

+ (NSString *) stringValue:(NSString *)key;
+ (NSInteger) intValue:(NSString *)key;
+ (NSArray *) listValue:(NSString *)key;

@end
