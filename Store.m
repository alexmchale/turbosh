#import "Store.h"

@implementation Store

NSString *path;
sqlite3 *db;

#pragma mark Connection

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

        /*
        tableSql = "CREATE TABLE kvs (k TEXT NOT NULL, v BLOB)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        tableSql = "CREATE UNIQUE INDEX kvs_idx (k, v)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);
        */
        
        tableSql = "CREATE TABLE projects ("
                   "id INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE AUTOINCREMENT, "
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

#pragma mark Project

+ (BOOL) loadProject:(Project *)project {
    assert(project != nil);
    assert(project.num != nil);
    
    BOOL found = FALSE;
    sqlite3_stmt *t;
    char *s = "SELECT name FROM projects WHERE id=?";
    assert(sqlite3_prepare_v2(db, s, -1, &t, NULL) == SQLITE_OK);
    assert(sqlite3_bind_int(t, 1, [project.num intValue]) == SQLITE_OK);
    
    switch (sqlite3_step(t)) {
    case SQLITE_ROW:
        project.name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(t, 0)];
        found = TRUE;
        break;
            
    case SQLITE_DONE:
        break;
            
    default:
        assert(1 != 1);
    }
    
    assert(sqlite3_finalize(t) == SQLITE_OK);
    
    return found;
}

+ (void) storeProject:(Project *)project {
    assert(project != nil);
    assert(project.name != nil);
    
    sqlite3_stmt *t;
    char *s = "INSERT INTO projects (id, name) VALUES (?, ?)";
    assert(sqlite3_prepare_v2(db, s, -1, &t, NULL) == SQLITE_OK);
    
    if (project.num)
        assert(sqlite3_bind_int(t, 1, [project.num intValue]) == SQLITE_OK);
    else
        assert(sqlite3_bind_null(t, 1) == SQLITE_OK);
    assert(sqlite3_bind_text(t, 2, [project.name UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    
    assert(sqlite3_step(t) == SQLITE_DONE);
    assert(sqlite3_finalize(t) == SQLITE_OK);
    
    project.num = [NSNumber numberWithInt:sqlite3_last_insert_rowid(db)];
}

+ (Project *) currentProject {
    NSInteger num = [self intValue:@"current.project"];
    Project *proj = [self findProjectByNum:num];
    
    if (proj == nil) {
        proj = [[[Project alloc] init] autorelease];
        proj.name = @"My Project";
        [self storeProject:proj];
        [self setCurrentProject:proj];
    }
    
    return proj;
}

+ (void) setCurrentProject:(Project *)project {
    assert(project != nil);
    assert(project.num != nil);
    
    [self setIntValue:[project.num intValue] forKey:@"current.project"];
}

+ (Project *) findProjectByNum:(NSInteger)num {
    Project *p = [[[Project alloc] init] autorelease];
    p.num = [NSNumber numberWithInt:num];
    
    if ([self loadProject:p]) return p;
    
    return nil;
}

+ (NSInteger) projectCount {
    return [self scalarInt:@"COUNT(id)" onTable:@"projects"];
}

+ (Project *) projectAtOffset:(NSInteger)offset {
    Project *p = [[[Project alloc] init] autorelease];
    NSInteger num = [self scalarInt:@"id" onTable:@"projects" offset:offset];
    
    if (num == 0) return nil;
    
    p.num = [NSNumber numberWithInt:num];
    
    if (![self loadProject:p]) return nil;
    
    return p;
}

#pragma mark ProjectFile

+ (NSInteger) fileCount:(Project *)project {
    return 0;
}

#pragma mark Key-Value

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

#pragma mark SQL Utilities

+ (NSString *) scalar:(NSString *)col
              onTable:(NSString *)tab
                where:(NSString *)where
               offset:(NSInteger)offset {
    
    sqlite3_stmt *t;
    NSString *f = @"SELECT %@ FROM %@ WHERE %@ LIMIT 1 OFFSET %d";
    NSString *s = [NSString stringWithFormat:f, col, tab, where, offset];
    NSString *v = nil;
    
    assert(sqlite3_prepare_v2(db, [s UTF8String], -1, &t, NULL) == SQLITE_OK);
    
    if (sqlite3_step(t) == SQLITE_ROW)
        v = [NSString stringWithUTF8String:(char *)sqlite3_column_text(t, 0)];
    
    assert(sqlite3_finalize(t) == SQLITE_OK);
    
    return v;
    
}

+ (NSInteger) scalarInt:(NSString *)col
                onTable:(NSString *)tab
                  where:(NSString *)where
                 offset:(NSInteger)offset {
    
    NSString *v = [self scalar:col onTable:tab where:where offset:offset];
    
    return (v == nil) ? 0 : [v intValue];

}

+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab {
    return [self scalarInt:col onTable:tab where:@"1=1" offset:0];
}

+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab offset:(NSInteger)offset {
    return [self scalarInt:col onTable:tab where:@"1=1" offset:offset];
}

@end
