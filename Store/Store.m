#import "Store.h"

@implementation Store

static NSString *path;
static sqlite3 *db;

#pragma mark Connection

+ (void) open {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [documentsPath stringByAppendingPathComponent:@"database.sqlite"];

    sqlite3_initialize();

    bool isNewDatabase = ![fileManager fileExistsAtPath:path];
    if (isNewDatabase) [fileManager createFileAtPath:path contents:nil attributes:nil];
    sqlite3_open([path UTF8String], &db);

    if (isNewDatabase) {
        char *tableSql;

        tableSql = "CREATE TABLE kv (k TEXT NOT NULL PRIMARY KEY ON CONFLICT REPLACE, v BLOB)";
        sqlite3_exec(db, tableSql, NULL, NULL, NULL);

        tableSql = "CREATE TABLE projects ("
                   "id INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE AUTOINCREMENT, "
                   "name TEXT NOT NULL, "
                   "ssh_hostname TEXT, "
                   "ssh_port INTEGER, "
                   "ssh_username TEXT, "
                   "ssh_password TEXT, "
                   "ssh_path TEXT"
                   ")";
        sqlite3_exec(db, tableSql, NULL, NULL, NULL);

        tableSql = "CREATE TABLE files ("
                   "id INTEGER NOT NULL PRIMARY KEY ON CONFLICT REPLACE AUTOINCREMENT, "
                   "project_id INTEGER NOT NULL, "
                   "path TEXT NOT NULL, "
                   "usage TEXT NOT NULL, "
                   "content BLOB, "
                   "remote_md5 TEXT, "
                   "local_md5 TEXT, "
                   "UNIQUE (project_id, path, usage) ON CONFLICT REPLACE)";
        sqlite3_exec(db, tableSql, NULL, NULL, NULL);

        [self setValue:@"1" forKey:@"version"];
    }

    const int CURRENT_VERSION = 2;

    for (int version = [self intValue:@"version"]; version < CURRENT_VERSION; ++version) {
        switch (version) {
            case 1:
            {
                const char *s = "UPDATE files SET path='./'||path WHERE usage LIKE 'task'";
                sqlite3_exec(db, s, NULL, NULL, NULL);

                break;
            }

            default: assert(false);
        }
    }

    [self setIntValue:CURRENT_VERSION forKey:@"version"];
}

+ (void) close {
    sqlite3_close(db);
}

#pragma mark SQLite Utils

static NSData *get_data(sqlite3_stmt *stmt, int column) {
    const char *data = sqlite3_column_blob(stmt, column);
    const int length = sqlite3_column_bytes(stmt, column);

    return [NSData dataWithBytes:data length:length];
}

static NSString *get_string(sqlite3_stmt *stmt, int column) {
    const NSData *data = get_data(stmt, column);

    return [data stringWithAutoEncoding];
}

static NSNumber *get_integer(sqlite3_stmt *stmt, int column) {
    NSString *str = get_string(stmt, column);

    if (str != nil)
        return [NSNumber numberWithInt:[str intValue]];
    else
        return nil;
}

static void bind_prepare(sqlite3_stmt **stmt, const char *sql) {
    sqlite3_prepare_v2(db, sql, -1, stmt, NULL);
}

static void bind_data(sqlite3_stmt *stmt, int column, NSData *d, bool allowNull) {
    assert(allowNull || d);

    if (!allowNull && !d) d = [NSData data];

    if (d != nil)
        sqlite3_bind_blob(stmt, column, [d bytes], [d length], SQLITE_TRANSIENT);
    else
        sqlite3_bind_null(stmt, column);
}

static void bind_string(sqlite3_stmt *stmt, int column, const NSString *s, bool allowNull) {
    assert(allowNull || s);

    if (!allowNull && !s) s = @"";

    if (s != nil)
        bind_data(stmt, column, [s dataWithAutoEncoding], allowNull);
    else
        sqlite3_bind_null(stmt, column);
}

static void bind_integer(sqlite3_stmt *stmt, int column, NSNumber *n, bool allowNull) {
    assert(allowNull || n);

    if (n != nil)
        sqlite3_bind_int(stmt, column, [n intValue]);
    else
        sqlite3_bind_null(stmt, column);
}

static bool bind_row(sqlite3_stmt *stmt) {
    return sqlite3_step(stmt) == SQLITE_ROW;
}

static void bind_finalize(sqlite3_stmt *stmt, int rowCount) {
    while (rowCount-- > 0)
        sqlite3_step(stmt);

    sqlite3_step(stmt);
    sqlite3_finalize(stmt);
}

static NSString *usage_str(FileUsage usage)
{
    switch (usage) {
        case FU_FILE: return @"file";
        case FU_TASK: return @"task";
        case FU_PATH: return @"path";

        default: assert(false);
    }

    return @"file";
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
    sqlite3_prepare_v2(db, s, -1, &t, NULL);
    sqlite3_bind_int(t, 1, [project.num intValue]);

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

    sqlite3_finalize(t);

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
    sqlite3_prepare_v2(db, s, -1, &t, NULL);

    bind_integer(t, 1, project.num, true);
    bind_string(t, 2, project.name, false);
    bind_string(t, 3, project.sshHost, true);
    bind_integer(t, 4, project.sshPort, true);
    bind_string(t, 5, project.sshUser, true);
    bind_string(t, 6, project.sshPass, true);
    bind_string(t, 7, project.sshPath, true);

    sqlite3_step(t);
    sqlite3_finalize(t);

    project.num = [NSNumber numberWithInt:sqlite3_last_insert_rowid(db)];
}

+ (void) deleteProject:(Project *)project
{
    assert(project.num);

    sqlite3_stmt *t;
    char *s;

    s = "DELETE FROM projects WHERE id=?";
    bind_prepare(&t, s);
    bind_integer(t, 1, project.num, false);
    bind_finalize(t, 0);

    s = "DELETE FROM files WHERE project_id=?";
    bind_prepare(&t, s);
    bind_integer(t, 1, project.num, false);
    bind_finalize(t, 0);

    // Reset the current project if this was the current.
    if ([project.num isEqualToNumber:[self currentProjectNum]]) {
        [self setIntValue:0 forKey:@"current.project"];
        [self currentProjectNum];
    }
}

+ (NSNumber *) currentProjectNum
{
    NSInteger num = [self intValue:@"current.project"];

    // Verify that the current project still exists.

    NSString *where = [NSString stringWithFormat:@"id=%d", num];
    NSString *name = [self scalar:@"name" onTable:@"projects" where:where offset:0 orderBy:@"name"];

    if (num > 0 && name != nil) return [NSNumber numberWithInt:num];

    // No project is marked as current.  Select the first available project.

    NSNumber *newCurrentProjectNum = [self projectNumAtOffset:0];

    if (newCurrentProjectNum != nil) {
        [self setIntValue:[newCurrentProjectNum intValue] forKey:@"current.project"];
        return newCurrentProjectNum;
    }

    // No projects exist.  Create a new one.

    Project *proj = [[Project alloc] init];
    proj.name = @"New Project";
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

+ (NSNumber *) projectNumAfterNum:(NSNumber *)num
{
    NSString *where = [NSString stringWithFormat:@"id>%d", [num intValue]];
    NSInteger nextNum = [self scalarInt:@"id" onTable:@"projects" where:where offset:0 orderBy:@"id"];

    return (nextNum > 0) ? [NSNumber numberWithInt:nextNum] : nil;
}

+ (bool) projectExists:(NSNumber *)num
{
    if (!num) return false;

    NSInteger currentNum = [num intValue];
    NSString *where = [NSString stringWithFormat:@"id=%d", currentNum];
    NSInteger thisNum = [self scalarInt:@"id" onTable:@"projects" where:where offset:0 orderBy:@"id"];

    return (thisNum != 0) && (currentNum == thisNum);
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

+ (NSInteger) fileCount:(Project *)project ofUsage:(FileUsage)usage
{
    assert(project);

    if (project.num == nil) return 0;

    NSString *idcl =
        [NSString stringWithFormat:@"project_id=%d AND usage LIKE '%@'",
            [project.num intValue],
            usage_str(usage)];

    return [self scalarInt:@"COUNT(id)" onTable:@"files" where:idcl offset:0 orderBy:@"id"];
}

+ (NSInteger) fileCountForCurrentProject:(FileUsage)usage
{
    Project *proj = [[[Project alloc] init] loadCurrent];
    NSInteger count = [self fileCount:proj ofUsage:usage];
    [proj release];

    return count;
}

+ (NSArray *) filenames:(Project *)project ofUsage:(FileUsage)usage
{
    NSMutableArray *filenames = [NSMutableArray array];

    assert(project.num != nil);

    sqlite3_stmt *stmt;
    const char *sql = "SELECT path FROM files WHERE project_id=? AND usage LIKE ?";
    sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
    sqlite3_bind_int(stmt, 1, [project.num intValue]);
    bind_string(stmt, 2, usage_str(usage), false);

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        [filenames addObject:get_string(stmt, 0)];
    }

    sqlite3_finalize(stmt);

    return filenames;
}

+ (void) deleteProjectFile:(ProjectFile *)file
{
    if (!file.num) return;

    const NSString *nsSql = [NSString stringWithFormat:@"DELETE FROM files WHERE id=%@", file.num];
    const char *sql = [nsSql UTF8String];
    sqlite3_exec(db, sql, NULL, NULL, NULL);
    file.num = nil;
}

void load_project_file(sqlite3_stmt *t, ProjectFile *file)
{
    NSNumber *loadedProjectId = get_integer(t, 1);

    if (file.project == nil) {
        assert(loadedProjectId != nil);

        Project *project = [[Project alloc] init];
        project.num = loadedProjectId;
        [Store loadProject:project];
        file.project = project;
        [project release];
    }

    file.num = get_integer(t, 0);
    file.filename = get_string(t, 2);
    file.remoteMd5 = get_string(t, 3);
    file.localMd5 = get_string(t, 4);
}

+ (BOOL) loadProjectFile:(ProjectFile *)file
{
    assert(file.num);

    const char *s = "SELECT id, project_id, path, remote_md5, local_md5 "
                    "FROM files "
                    "WHERE id=?";

    BOOL found = FALSE;
    sqlite3_stmt *t;
    sqlite3_prepare_v2(db, s, -1, &t, NULL);
    sqlite3_bind_int(t, 1, [file.num intValue]);

    switch (sqlite3_step(t)) {
        case SQLITE_ROW:
        {
            load_project_file(t, file);

            found = TRUE;
        }   break;

        case SQLITE_DONE:
            found = FALSE;
            break;

        default:
            assert(1 != 1);
    }

    sqlite3_finalize(t);

    return found;
}

+ (NSArray *) files:(Project *)project ofUsage:(FileUsage)usage
{
    if (!project.num) return [NSArray array];

    const char *s = "SELECT id, project_id, path, remote_md5, local_md5 "
                    "FROM files "
                    "WHERE project_id=? AND usage LIKE ?";

    NSMutableArray *files = [NSMutableArray array];
    sqlite3_stmt *t;
    bind_prepare(&t, s);
    bind_integer(t, 1, project.num, false);
    bind_string(t, 2, usage_str(usage), false);

    while (bind_row(t)) {
        ProjectFile *file = [[ProjectFile alloc] init];

        file.usage = usage;
        load_project_file(t, file);
        [files addObject:file];

        [file release];
    }

    bind_finalize(t, 0);

    return files;
}

+ (void) storeProjectFile:(ProjectFile *)file
{
    assert(file.project);

    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO files (id, project_id, path, usage) VALUES (?, ?, ?, ?)";
    sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
    bind_integer(stmt, 1, file.num, true);
    bind_integer(stmt, 2, file.project.num, false);
    bind_string(stmt, 3, file.filename, false);
    bind_string(stmt, 4, usage_str(file.usage), false);
    bind_finalize(stmt, 0);
}

+ (void) storeLocal:(ProjectFile *)file content:(NSData *)content
{
    if (!file.num || !content) return;

    const NSString *md5 = hex_md5(content);

    sqlite3_stmt *stmt;
    const char *sql = "UPDATE FILES SET local_md5=?, content=? WHERE id=?";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, md5, false);
    bind_data(stmt, 2, content, false);
    bind_integer(stmt, 3, file.num, false);
    bind_finalize(stmt, 0);
}

+ (void) storeRemote:(ProjectFile *)file content:(NSData *)content
{
    if (!file.num || !content) return;

    const NSString *md5 = hex_md5(content);

    sqlite3_stmt *stmt;
    const char *sql = "UPDATE FILES SET local_md5=?, remote_md5=?, content=? WHERE id=?";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, md5, false);
    bind_string(stmt, 2, md5, false);
    bind_data(stmt, 3, content, false);
    bind_integer(stmt, 4, file.num, false);
    bind_finalize(stmt, 0);
}

+ (NSData *) fileContent:(ProjectFile *)file
{
    if (!file.num) return nil;

    NSData *content = nil;

    sqlite3_stmt *stmt;
    const char *sql = "SELECT content FROM files WHERE id=?";
    bind_prepare(&stmt, sql);
    bind_integer(stmt, 1, file.num, false);

    if (bind_row(stmt)) {
        content = get_data(stmt, 0);
    }

    bind_finalize(stmt, 0);

    return content;
}

+ (NSNumber *) projectFileNumber:(Project *)project
                        filename:(NSString *)filename
                         ofUsage:(FileUsage)usage
{
    assert(project.num);

    if (!project.num) return nil;

    NSNumber *num = nil;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT id FROM files WHERE project_id=? AND path LIKE ? AND usage LIKE ?";
    bind_prepare(&stmt, sql);
    bind_integer(stmt, 1, project.num, false);
    bind_string(stmt, 2, filename, false);
    bind_string(stmt, 3, usage_str(usage), false);

    if (bind_row(stmt))
        num = get_integer(stmt, 0);

    bind_finalize(stmt, 0);

    return num;
}

+ (NSNumber *) projectFileNumber:(Project *)project
                        atOffset:(NSInteger)offset
                         ofUsage:(FileUsage)usage
{
    assert(project != nil);
    assert(project.num != nil);

    NSString *wherecl =
        [NSString stringWithFormat:@"project_id=%d AND usage LIKE '%@'",
            [project.num intValue],
            usage_str(usage)];

    NSInteger idint = [self scalarInt:@"id" onTable:@"files" where:wherecl offset:offset orderBy:@"path"];

    return (idint > 0) ? [NSNumber numberWithInt:idint] : nil;
}

+ (bool) fileExists:(NSNumber *)num
{
    if (!num) return false;

    NSInteger currentNum = [num intValue];
    NSString *where = [NSString stringWithFormat:@"id=%d", currentNum];
    NSInteger thisNum = [self scalarInt:@"id" onTable:@"files" where:where offset:0 orderBy:@"id"];

    return (thisNum != 0) && (currentNum == thisNum);
}

#pragma mark Font Configuration

+ (void) setFontSize:(NSInteger)size
{
    [self setIntValue:size forKey:@"current.font.size"];
}

+ (NSInteger) fontSize
{
    NSInteger size = [self intValue:@"current.font.size"];

    return size > 0 ? size : 14;
}

#pragma mark Key-Value

+ (void) setValue:(NSString *)value forKey:(NSString *)key {
    sqlite3_stmt *stmt;
    const char *sql = "INSERT INTO kv (k, v) VALUES (?, ?)";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, key, false);
    bind_string(stmt, 2, value, false);
    bind_finalize(stmt, 0);
}

+ (void) setIntValue:(NSInteger)value forKey:(NSString *)key {
    NSString *stringValue = [NSString stringWithFormat:@"%d", value];
    [self setValue:stringValue forKey:key];
}

+ (NSString *) stringValue:(NSString *)key {
    NSString *value = nil;

    sqlite3_stmt *stmt;
    const char *sql = "SELECT v FROM kv WHERE k LIKE ?";
    bind_prepare(&stmt, sql);
    bind_string(stmt, 1, key, false);

    if (bind_row(stmt)) {
        value = get_string(stmt, 0);
    }

    bind_finalize(stmt, 0);

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
              orderBy:(NSString *)order
{
    sqlite3_stmt *stmt;
    NSString *f = @"SELECT %@ FROM %@ WHERE %@ ORDER BY %@ LIMIT 1 OFFSET %d";
    NSString *s = [NSString stringWithFormat:f, col, tab, where, order, offset];
    NSString *v = nil;

    bind_prepare(&stmt, [s UTF8String]);

    if (bind_row(stmt)) v = get_string(stmt, 0);

    bind_finalize(stmt, 0);

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
