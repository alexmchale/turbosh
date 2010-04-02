#import "ProjectFile.h"

@implementation ProjectFile

@synthesize num;
@synthesize project;
@synthesize filename;

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

- (NSString *)content {
    return @"";
}

- (void) setContent:(NSString *)content {
}

@end
