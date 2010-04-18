#import <Foundation/Foundation.h>

@interface FileUploader : NSObject
{
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;

    ProjectFile *file;
    NSData *content;
    int offset;

    int step;
    bool success;
}

- (id) initWithSession:(LIBSSH2_SESSION *)session file:(ProjectFile *)file;
- (bool) step;
- (bool) close;
- (bool) succeeded;

@end
