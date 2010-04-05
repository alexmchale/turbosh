#import "ProjectFile.h"

@implementation ProjectFile

@synthesize num;
@synthesize project;
@synthesize filename, localMd5, remoteMd5;

#pragma mark Initializers

- (id) initByNumber:(NSNumber *)number {
    assert(self = [self init]);
    assert(number != nil);
    
    self.num = number;
    self.project = nil;
    self.filename = nil;
    self.localMd5 = nil;
    self.remoteMd5 = nil;
    [Store loadProjectFile:self];
    
    return self;
}

- (id) initByProject:(Project *)myProject filename:(NSString *)myFilename {
    assert(self = [self init]);
    assert(myProject != nil);
    assert(myProject.num != nil);
    assert(myFilename != nil);
    
    self.num = [Store projectFileNumber:myProject filename:myFilename];
    self.project = myProject;
    self.filename = myFilename;
    self.localMd5 = nil;
    self.remoteMd5 = nil;
    
    if (self.num) [Store loadProjectFile:self];
    
    assert([filename isEqual:myFilename]);
    
    return self;
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
    return [[self fullpath] stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

#pragma mark Content

- (NSString *) content {
    return [Store fileContent:self];
}

- (NSString *) contentType {
    NSDictionary *types = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ruby", @"rb",
        @"javascript", @"js",
        nil
    ];

    NSString *ext = [self extension];
    NSString *type = [types objectForKey:ext];
    
    return type ? type : ext;
}

- (NSString *) extension {
    NSArray *segments = [filename componentsSeparatedByString:@"."];
    
    if (!segments || [segments count] < 2) return @"";

    return [segments lastObject];
}

- (void) setContent:(NSString *)content {
}

#pragma mark Memory

- (void) dealloc
{
    [super dealloc];
    
    [num release];
    [project release];
    [filename release];
    [localMd5 release];
    [remoteMd5 release];
}

@end
