#import "ProjectFile.h"

@implementation ProjectFile

@synthesize num;
@synthesize project;
@synthesize filename, localMd5, remoteMd5;
@synthesize usage;

#pragma mark Data Loaders

- (id) loadByNumber:(NSNumber *)number
{
    assert(number != nil);

    self.num = number;
    self.project = nil;
    self.filename = nil;
    self.localMd5 = nil;
    self.remoteMd5 = nil;

    [Store loadProjectFile:self];

    return self;
}

- (id) loadByProject:(Project *)myProject
            filename:(NSString *)myFilename
            forUsage:(FileUsage)myUsage
{
    assert(myProject != nil);
    assert(myProject.num != nil);
    assert(myFilename != nil);

    self.num = [Store projectFileNumber:myProject filename:myFilename ofUsage:myUsage];
    self.project = myProject;
    self.filename = myFilename;
    self.localMd5 = nil;
    self.remoteMd5 = nil;
    self.usage = myUsage;

    if (self.num) [Store loadProjectFile:self];

    [filename isEqual:myFilename];

    return self;
}

- (bool) existsInDatabase
{
    return [Store fileExists:num];
}

#pragma mark Memory Management

- (id) init
{
    self = [super init];

    num = nil;
    project = nil;
    filename = nil;
    localMd5 = nil;
    remoteMd5 = nil;

    return self;
}

- (void) dealloc
{
    [num release];
    [project release];
    [filename release];
    [localMd5 release];
    [remoteMd5 release];

    [super dealloc];
}

#pragma mark Path Accessors

- (NSString *) condensedPath {
    assert(filename != nil);

    NSArray *segments = [filename componentsSeparatedByString:@"/"];
    NSMutableArray *esegs = [NSMutableArray arrayWithArray:segments];

    for (int i = 0; i < [esegs count] - 1; ++i) {
        NSString *a = [esegs objectAtIndex:i];

        if ([[esegs objectAtIndex:i] length] > 0) {
            NSString *b = [a substringToIndex:1];
            [esegs replaceObjectAtIndex:i withObject:b];
        }
    }

    return [esegs componentsJoinedByString:@"/"];
}

- (NSString *) fullpath {
    NSString *root = project.sshPath;
    assert(root);
    return [NSString stringWithFormat:@"%@/%@", root, filename];
}

- (NSString *) escapedPath {
    return [[self fullpath] stringBySingleQuoting];
}

- (NSString *) escapedRelativePath {
    return [self.filename stringBySingleQuoting];
}

#pragma mark Content

- (NSString *) content {
    return [Store fileContent:self];
}

- (NSString *) contentType {
    NSDictionary *types = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ruby",       @"rb",
        @"javascript", @"js",
        @"bison",      @"y",
        @"bison",      @"ypp",
        @"bison",      @"y++",
        @"bison",      @"yxx",
        @"csharp",     @"cs",
        @"cpp",        @"c++",
        @"cpp",        @"cc",
        @"cpp",        @"cxx",
        @"latex",      @"tex",
        @"python",     @"py",
        @"php",        @"php3",
        @"php",        @"php4",
        @"perl",       @"pl",
        nil
    ];

    NSString *ext = [[self extension] lowercaseString];
    NSString *type = [types objectForKey:ext];

    return type ? type : ext;
}

- (NSString *) extension {
    NSArray *segments = [filename componentsSeparatedByString:@"."];

    if (!segments || [segments count] < 2) return @"";

    return [segments lastObject];
}

@end
