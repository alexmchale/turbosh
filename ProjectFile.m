#import "ProjectFile.h"

@implementation ProjectFile

@synthesize proj;
@synthesize filename;

- (id) initByProject:(Project *)myProject filename:(NSString *)myFilename {
    self.proj = myProject;
    self.filename = myFilename;
    
    return self;
}

- (NSString *)content {
    return @"";
}

- (void) setContent:(NSString *)content {
}

@end
