#import <Foundation/Foundation.h>

@interface KeyPair : NSObject
{
}

- (id) generate;
- (NSString *) publicFilename;
- (NSString *) privateFilename;

@end
