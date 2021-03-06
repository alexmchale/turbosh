#import <Foundation/Foundation.h>

@interface FileTransfer : NSObject
{
    LIBSSH2_SESSION *session;
    LIBSSH2_CHANNEL *channel;

    ProjectFile *file;
    NSString *filePartialName;
    NSMutableData *content;
    int offset;
    struct stat sb;
    CommandDispatcher *fileMover;

    int step;
    bool success;
    bool isUpload;
}

- (id) initWithSession:(LIBSSH2_SESSION *)session upload:(ProjectFile *)file;
- (id) initWithSession:(LIBSSH2_SESSION *)session download:(ProjectFile *)file;
- (bool) step;
- (bool) close:(int)rc;
- (bool) succeeded;

@end
