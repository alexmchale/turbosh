#import "Store.h"

@implementation Store

typedef enum {
    STORE_STRING,
    STORE_SET
} StoreDataType;

NSString *listGlue = @"+!List!Join!+";
NSString *path;
sqlite3 *db;

+ (void) open {
    path = [[[NSBundle mainBundle] resourcePath] stringByAppendingFormat:@"/database.sqlite"];
    bool isNewDatabase = ![[NSFileManager defaultManager] fileExistsAtPath:path];
    assert(sqlite3_initialize() == SQLITE_OK);
    assert(sqlite3_open([path UTF8String], &db) == SQLITE_OK);
    
    if (isNewDatabase) {
        char *tableSql;
        
        tableSql = "CREATE TABLE idseq (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        
        tableSql = "CREATE TABLE kv (k TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE, v BLOB)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        
        tableSql = "CREATE TABLE kvs (k TEXT NOT NULL, v BLOB)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        tableSql = "CREATE UNIQUE INDEX kvs_idx (k, v)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        
        tableSql = "CREATE TABLE projects ("
                   "id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "
                   "name TEXT NOT NULL UNIQUE"
                   ")";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        
        [self setValue:@"1" forKey:@"version"];
        assert([@"1" isEqual:[self stringValue:@"version"]]);
    }
}

+ (void) close {
    assert(sqlite3_close(db) == SQLITE_OK);
}

+ (void) loadProject:(Project *)project {
}

+ (void) storeProject:(Project *)project {
}

+ (NSInteger) nextId {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO idseq (id) VALUES (NULL)";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
    assert(sqlite3_exec(db, "DELETE FROM idseq", NULL, NULL, NULL) == SQLITE_OK);
    return sqlite3_last_insert_rowid(db);
}

+ (void) setValue:(NSString *)value forKey:(NSString *)key {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO kv (k, v) VALUES (?, ?)";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_bind_blob(stmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key {
    NSString *stringValue = [NSString stringWithFormat:@"%d", value];
    [self setValue:stringValue forKey:key];
}

+ (void) addToSet:(NSString *)value forKey:(NSString *)key {
    sqlite3_stmt *stmt;
     
    const char *sql = "INSERT INTO kvs (k, v) VALUES (?, ?)";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_bind_blob(stmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (void) removeFromSet:(NSString *)value forKey:(NSString *)key {
    sqlite3_stmt *stmt;
    
    const char *sql = "DELETE FROM kvs WHERE k LIKE ? AND v LIKE ?";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_bind_blob(stmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (BOOL) isInSet:(NSString *)value forKey:(NSString *)key {
    sqlite3_stmt *stmt;
    BOOL exists = FALSE;
    
    const char *sql = "SELECT value FROM kvs WHERE k LIKE ? AND v LIKE ?";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    assert(sqlite3_bind_blob(stmt, 2, [value UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    
    if (sqlite3_step(stmt) == SQLITE_ROW)
        exists = TRUE;

    assert(sqlite3_finalize(stmt) == SQLITE_OK);    
    
    return exists;
}

+ (void) setList:(NSArray *)values forKey:(NSString *)key {
    NSString *value = [values componentsJoinedByString:listGlue];
    [self setValue:value forKey:key];
}

+ (void) insertSetValue:(NSString *)value forKey:(NSString *)key {
    NSArray *values = [self listValue:key];
    
    for (NSString *v in values) {
        if ([v isEqual:value]) return;
    }
    
    NSMutableArray *newValues = [NSMutableArray arrayWithArray:values];
    [newValues addObject:value];
    [self setList:newValues forKey:key];
}

+ (void) removeListValue:(NSString *)value forKey:(NSString *)key {
    NSArray *values = [self listValue:key];
    NSMutableArray *newValues = [NSMutableArray arrayWithArray:values];
    [newValues removeObject:value];
    [self setList:newValues forKey:key];
}

+ (NSString *) stringValue:(NSString *)key {
    char *cValue = NULL;
    NSString *value = nil;
    
    sqlite3_stmt *selStmt;
    NSString *selSql = @"SELECT v FROM kv WHERE k LIKE ?";
    assert(sqlite3_prepare_v2(db, [selSql UTF8String], -1, &selStmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(selStmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    
    switch(sqlite3_step(selStmt)) {
    case SQLITE_ROW:
        cValue = (char *)sqlite3_column_text(selStmt, 0);
        if (cValue != NULL)
            value = [NSString stringWithUTF8String:cValue];
        break;
        
    case SQLITE_DONE:
        break;
        
    default:
        assert(1 != 1);
        break;
    }
    
    assert(sqlite3_finalize(selStmt) == SQLITE_OK);
    
    return value;
}

+ (NSInteger) intValue:(NSString *)key {
    NSString *value = [self stringValue:key];
    
    return value ? [value intValue] : 0;
}

+ (NSArray *) listValue:(NSString *)key {
    NSString *value = [self stringValue:key];
    
    if (value == nil)
        return [NSArray arrayWithObjects:nil];
    else
        return [value componentsSeparatedByString:listGlue];
}

@end
