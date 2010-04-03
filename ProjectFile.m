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

- (NSString *) escapedPath {
    NSString *root = project.sshPath;
    NSString *path = [NSString stringWithFormat:@"%@/%@", root, filename];
    
    return [path stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
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
