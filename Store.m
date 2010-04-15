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
                   "name TEXT NOT NULL UNIQUE, "
                   "ssh_hostname TEXT, "
                   "ssh_port INTEGER, "
                   "ssh_username TEXT, "
                   "ssh_password TEXT, "
                   "ssh_path TEXT"
                   ")";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);

        tableSql = "CREATE TABLE files ("
                   "id INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE AUTOINCREMENT, "
                   "project_id INTEGER NOT NULL, "
                   "path TEXT NOT NULL, "
                   "content BLOB, "
                   "remote_md5 TEXT, "
                   "local_md5 TEXT, "
                   "UNIQUE (project_id, path) ON CONFLICT REPLACE)";
        assert(sqlite3_exec(db, tableSql, NULL, NULL, NULL) == SQLITE_OK);

        [self setValue:@"1" forKey:@"version"];
        assert([@"1" isEqual:[self stringValue:@"version"]]);
    }
}

+ (void) close {
    assert(sqlite3_close(db) == SQLITE_OK);
}

#pragma mark SQLite Utils

static NSString *get_string(sqlite3_stmt *stmt, int column) {
    char *cString = (char *)sqlite3_column_text(stmt, column);

    if (cString == NULL) return nil;

    return [NSString stringWithUTF8String:cString];
}

static NSNumber *get_integer(sqlite3_stmt *stmt, int column) {
    NSString *str = get_string(stmt, column);

    if (str != nil)
        return [NSNumber numberWithInt:[str intValue]];
    else
        return nil;
}

static void bind_prepare(sqlite3_stmt **stmt, const char *sql) {
    assert(sqlite3_prepare_v2(db, sql, -1, stmt, NULL) == SQLITE_OK);
}

static void bind_string(sqlite3_stmt *stmt, int column, const NSString *s, bool allowNull) {
    assert(allowNull || s);

    if (s != nil)
        assert(sqlite3_bind_text(stmt, column, [s UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);
    else
        assert(sqlite3_bind_null(stmt, column) == SQLITE_OK);
}

static void bind_integer(sqlite3_stmt *stmt, int column, NSNumber *n, bool allowNull) {
    assert(allowNull || n);

    if (n != nil)
        assert(sqlite3_bind_int(stmt, column, [n intValue]) == SQLITE_OK);
    else
        assert(sqlite3_bind_null(stmt, column) == SQLITE_OK);
}

static void bind_data(sqlite3_stmt *stmt, int column, NSData *d, bool allowNull) {
    assert(allowNull || d);

    if (d != nil)
        assert(sqlite3_bind_blob(stmt, column, [d bytes], [d length], SQLITE_TRANSIENT) == SQLITE_OK);
    else
        assert(sqlite3_bind_null(stmt, column) == SQLITE_OK);
}

#pragma mark Project

+ (BOOL) loadProject:(Project *)project {
    assert(project != nil);
    assert(project.num != nil);

    char *s = "SELECT name, "
              "ssh_hostname, ssh_port, "
              "ssh_username, ssh_password, ssh_path "
              "FROM projects "
              "WHERE id=?";

    BOOL found = FALSE;
    sqlite3_stmt *t;
    assert(sqlite3_prepare_v2(db, s, -1, &t, NULL) == SQLITE_OK);
    assert(sqlite3_bind_int(t, 1, [project.num intValue]) == SQLITE_OK);

    switch (sqlite3_step(t)) {
        case SQLITE_ROW:
            project.name = get_string(t, 0);
            project.sshHost = get_string(t, 1);
            project.sshPort = get_integer(t, 2);
            project.sshUser = get_string(t, 3);
            project.sshPass = get_string(t, 4);
            project.sshPath = get_string(t, 5);

            found = TRUE;
            break;

        case SQLITE_DONE:
            found = FALSE;
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
    char *s = "INSERT INTO projects ("
              "id, name, "
              "ssh_hostname, ssh_port, ssh_username, ssh_password, ssh_path"
              ") VALUES (?, ?, ?, ?, ?, ?, ?)";
    assert(sqlite3_prepare_v2(db, s, -1, &t, NULL) == SQLITE_OK);

    bind_integer(t, 1, project.num, true);
    bind_string(t, 2, project.name, false);
    bind_string(t, 3, project.sshHost, true);
    bind_integer(t, 4, project.sshPort, true);
    bind_string(t, 5, project.sshUser, true);
    bind_string(t, 6, project.sshPass, true);
    bind_string(t, 7, project.sshPath, true);

    assert(sqlite3_step(t) == SQLITE_DONE);
    assert(sqlite3_finalize(t) == SQLITE_OK);

    project.num = [NSNumber numberWithInt:sqlite3_last_insert_rowid(db)];
}

+ (NSNumber *) currentProjectNum
{
    NSInteger num = [self intValue:@"current.project"];

    if (num > 0) return [NSNumber numberWithInt:num];

    // No project is marked as current.  Create a new one.

    Project *proj = [[Project alloc] init];
    proj.name = @"My Project";
    [self storeProject:proj];
    [self setCurrentProject:proj];
    assert(proj.num != nil);
    NSNumber *number = [NSNumber numberWithInt:[proj.num intValue]];
    [proj release];

    return number;
}

+ (void) setCurrentProject:(Project *)project {
    assert(project != nil);
    assert(project.num != nil);

    [self setIntValue:[project.num intValue] forKey:@"current.project"];
}

+ (NSInteger) projectCount {
    return [self scalarInt:@"COUNT(id)" onTable:@"projects"];
}

+ (NSNumber *) projectNumAtOffset:(NSInteger)offset
{
    NSInteger num = [self scalarInt:@"id" onTable:@"projects" offset:offset orderBy:@"name"];

    if (num == 0) return nil;

    return [NSNumber numberWithInt:num];
}

#pragma mark ProjectFile

+ (NSNumber *) currentFileNum
{
    NSInteger num = [self intValue:@"current.file"];

    return (num > 0) ? [NSNumber numberWithInt:num] : nil;
}

+ (void) setCurrentFile:(ProjectFile *)file
{
    if (file != nil)
        [self setIntValue:[file.num intValue] forKey:@"current.file"];
    else
        [self setIntValue:0 forKey:@"current.file"];
}

+ (NSInteger) fileCount:(Project *)project {
    assert(project != nil);
    if (project.num == nil) return 0;

    NSString *idcl = [NSString stringWithFormat:@"project_id=%d", [project.num intValue]];
    return [self scalarInt:@"COUNT(id)" onTable:@"files" where:idcl offset:0 orderBy:@"id"];
}

+ (NSInteger) fileCountForCurrentProject {
    Project *proj = [[[Project alloc] init] loadCurrent];
    NSInteger count = [self fileCount:proj];
    [proj release];

    return count;
}

+ (NSArray *) filenames:(Project *)project {
    NSMutableArray *filenames = [NSMutableArray array];

    assert(project.num != nil);

    sqlite3_stmt *stmt;
    const char *sql = "SELECT path FROM files WHERE project_id=?";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_int(stmt, 1, [project.num intValue]) == SQLITE_OK);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        [filenames addObject:get_string(stmt, 0)];
    }

    assert(sqlite3_finalize(stmt) == SQLITE_OK);

    return filenames;
}

+ (void) deleteProjectFile:(ProjectFile *)file {
    assert(file.num != nil);
    const NSString *nsSql = [NSString stringWithFormat:@"DELETE FROM files WHERE id=%@", file.num];
    const char *sql = [nsSql UTF8String];
    assert(sqlite3_exec(db, sql, NULL, NULL, NULL) == SQLITE_OK);
    file.num = nil;
}

+ (BOOL) loadProjectFile:(ProjectFile *)file {
    assert(file.num != nil);

    const char *s = "SELECT project_id, path, remote_md5, local_md5 "
                    "FROM files "
                    "WHERE id=?";

    BOOL found = FALSE;
    sqlite3_stmt *t;
    assert(sqlite3_prepare_v2(db, s, -1, &t, NULL) == SQLITE_OK);
    assert(sqlite3_bind_int(t, 1, [file.num intValue]) == SQLITE_OK);

    switch (sqlite3_step(t)) {
        case SQLITE_ROW:
        {
            NSNumber *loadedProjectId = get_integer(t, 0);

            if (file.project == nil) {
                assert(loadedProjectId != nil);

                Project *project = [[Project alloc] init];
                project.num = loadedProjectId;
                assert([Store loadProject:project]);
                file.project = project;
                [project release];
            }

            assert([file.project.num isEqualToNumber:loadedProjectId]);

            file.filename = get_string(t, 1);
            file.remoteMd5 = get_string(t, 2);
            file.localMd5 = get_string(t, 3);

            found = TRUE;
        }   break;

        case SQLITE_DONE:
            found = FALSE;
            break;

        default:
            assert(1 != 1);
    }

    assert(sqlite3_finalize(t) == SQLITE_OK);

    return found;
}

+ (void) storeProjectFile:(ProjectFile *)file {
    assert(file.project != nil);

    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO files (id, project_id, path) VALUES (?, ?, ?)";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    bind_integer(stmt, 1, file.num, true);
    bind_integer(stmt, 2, file.project.num, false);
    bind_string(stmt, 3, file.filename, false);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (void) storeLocal:(ProjectFile *)file content:(NSData *)content
{
    const NSString *md5 = hex_md5(content);

    sqlite3_stmt *stmt;
    const char *sql = "UPDATE FILES SET local_md5=?, content=? WHERE id=?";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, md5, false);
    bind_data(stmt, 2, content, false);
    bind_integer(stmt, 3, file.num, false);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (void) storeRemote:(ProjectFile *)file content:(NSData *)content
{
    const NSString *md5 = hex_md5(content);

    sqlite3_stmt *stmt;
    const char *sql = "UPDATE FILES SET local_md5=?, remote_md5=?, content=? WHERE id=?";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, md5, false);
    bind_string(stmt, 2, md5, false);
    bind_data(stmt, 3, content, false);
    bind_integer(stmt, 4, file.num, false);
    assert(sqlite3_step(stmt) == SQLITE_DONE);
    assert(sqlite3_finalize(stmt) == SQLITE_OK);
}

+ (NSString *) fileContent:(ProjectFile *)file
{
    assert(file.num != nil);
    NSInteger num = [file.num intValue];
    NSString *fileid = [NSString stringWithFormat:@"id=%d", num];
    return [self scalar:@"content" onTable:@"files" where:fileid offset:0 orderBy:@"id"];
}

+ (NSNumber *) projectFileNumber:(Project *)project
                        filename:(NSString *)filename
{
    assert(project.num != nil);

    NSNumber *num = nil;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT id FROM files WHERE project_id=? AND path=?";
    assert(sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_int(stmt, 1, [project.num intValue]) == SQLITE_OK);
    assert(sqlite3_bind_text(stmt, 2, [filename UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);

    if (sqlite3_step(stmt) == SQLITE_ROW)
        num = get_integer(stmt, 0);

    assert(sqlite3_finalize(stmt) == SQLITE_OK);

    return num;
}

+ (NSNumber *) projectFileNumber:(Project *)project atOffset:(NSInteger)offset
{
    assert(project != nil);
    assert(project.num != nil);

    NSString *wherecl = [NSString stringWithFormat:@"project_id=%d", [project.num intValue]];
    NSInteger idint = [self scalarInt:@"id" onTable:@"files" where:wherecl offset:offset orderBy:@"path"];

    assert(idint > 0);

    return [NSNumber numberWithInt:idint];
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
    NSString *value = nil;

    sqlite3_stmt *selStmt;
    NSString *selSql = @"SELECT v FROM kv WHERE k LIKE ?";
    assert(sqlite3_prepare_v2(db, [selSql UTF8String], -1, &selStmt, NULL) == SQLITE_OK);
    assert(sqlite3_bind_text(selStmt, 1, [key UTF8String], -1, SQLITE_TRANSIENT) == SQLITE_OK);

    switch(sqlite3_step(selStmt)) {
    case SQLITE_ROW:
        value = get_string(selStmt, 0);
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
               offset:(NSInteger)offset
              orderBy:(NSString *)order {

    sqlite3_stmt *t;
    NSString *f = @"SELECT %@ FROM %@ WHERE %@ ORDER BY %@ LIMIT 1 OFFSET %d";
    NSString *s = [NSString stringWithFormat:f, col, tab, where, order, offset];
    NSString *v = nil;

    assert(sqlite3_prepare_v2(db, [s UTF8String], -1, &t, NULL) == SQLITE_OK);

    if (sqlite3_step(t) == SQLITE_ROW)
        v = get_string(t, 0);

    assert(sqlite3_finalize(t) == SQLITE_OK);

    return v;

}

+ (NSInteger) scalarInt:(NSString *)col
                onTable:(NSString *)tab
                  where:(NSString *)where
                 offset:(NSInteger)offset
                orderBy:(NSString *)order {

    NSString *v = [self scalar:col onTable:tab where:where offset:offset orderBy:order];

    return (v == nil) ? 0 : [v intValue];

}

+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab {
    return [self scalarInt:col onTable:tab where:@"1=1" offset:0 orderBy:@"id"];
}

+ (NSInteger) scalarInt:(NSString *)col onTable:(NSString *)tab offset:(NSInteger)offset orderBy:(NSString *)order {
    return [self scalarInt:col onTable:tab where:@"1=1" offset:offset orderBy:order];
}

@end
