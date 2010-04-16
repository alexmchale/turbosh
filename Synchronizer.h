#import <Foundation/Foundation.h>

enum SyncState
{
    SS_SELECT_PROJECT,
    SS_CONNECT_TO_SERVER,
    SS_ESTABLISH_SSH,
    SS_SELECT_FILE,
    SS_INITIATE_HASH,
    SS_CONTINUE_HASH,
    SS_COMPLETE_HASH,
    SS_TEST_IF_CHANGED,
    SS_INITIATE_UPLOAD,
    SS_CONTINUE_UPLOAD,
    SS_COMPLETE_UPLOAD,
    SS_INITIATE_DOWNLOAD,
    SS_CONTINUE_DOWNLOAD,
    SS_COMPLETE_DOWNLOAD,
    SS_TERMINATE_SSH,
    SS_DISCONNECT
};

@interface Synchronizer : NSObject
{
    enum SyncState state;

    NSTimer *timer;

    Project *project;
    ProjectFile *file;

    NSString *localHash;
    NSString *remoteHash;

    NSData *localContent;

    int sock;
}

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) ProjectFile *file;

- (void) step;

@end
