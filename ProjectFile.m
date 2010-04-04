#import "ProjectFile.h"

@implementation ProjectFile

@synthesize num;
@synthesize project;
@synthesize filename, localMd5, remoteMd5;

- (id) initByNumber:(NSNumber *)number {
    assert(number != nil);
    
    self.num = number;
    [Store loadProjectFile:self];
    
    return self;
}

- (id) initByProject:(Project *)myProject filename:(NSString *)myFilename {
    self.num = [Store projectFileNumber:myProject filename:myFilename];
    
    self.project = myProject;
    self.filename = myFilename;
    
    return self;
}

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

- (NSString *)content {
    return @"";
}

- (void) setContent:(NSString *)content {
}

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
