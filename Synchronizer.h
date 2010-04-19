#import <Foundation/Foundation.h>

enum SyncState
{
    SS_SELECT_PROJECT,
    SS_CONNECT_TO_SERVER,
    SS_ESTABLISH_SSH,
    SS_AUTHENTICATE_SSH,
    SS_SELECT_FILE,
    SS_INITIATE_HASH,
    SS_CONTINUE_HASH,
    SS_COMPLETE_HASH,
    SS_FILE_IS_MISSING,
    SS_TEST_IF_CHANGED,
    SS_INITIATE_UPLOAD,
    SS_INITIATE_DOWNLOAD,
    SS_CONTINUE_TRANSFER,
    SS_COMPLETE_TRANSFER,
    SS_TERMINATE_SSH,
    SS_DISCONNECT,
    SS_IDLE
};

@interface Synchronizer : NSObject
{
    enum SyncState state;

    NSTimer *timer;

    Project *project;
    ProjectFile *file;
    NSInteger nextFileOffset;

    NSString *localHash;
    NSString *remoteHash;

    NSData *localContent;

    int sock;
    LIBSSH2_SESSION *session;
    CommandDispatcher *dispatcher;
    FileTransfer *transfer;

    bool startup;
}

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) ProjectFile *file;
@property (nonatomic, retain) CommandDispatcher *dispatcher;
@property (nonatomic, retain) FileTransfer *transfer;

- (void) step;
- (void) synchronize;

@end
