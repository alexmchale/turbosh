#import <Foundation/Foundation.h>

typedef enum
{
    SS_SELECT_PROJECT,
    SS_BEGIN_CONN,
    SS_ESTABLISH_CONN,
    SS_ESTABLISH_SSH,
    SS_REQUEST_AUTH_TYPE,
    SS_AUTHENTICATE_SSH_BY_KEY,
    SS_AUTHENTICATE_SSH_BY_PASSWORD,
    SS_EXECUTE_COMMAND,
    SS_INITIATE_LIST,
    SS_CONTINUE_LIST,
    SS_SELECT_FILE,
    SS_INITIATE_HASH,
    SS_CONTINUE_HASH,
    SS_COMPLETE_HASH,
    SS_FILE_IS_MISSING,
    SS_DELETE_LOCAL_FILE,
    SS_TEST_IF_CHANGED,
    SS_INITIATE_UPLOAD,
    SS_INITIATE_DOWNLOAD,
    SS_CONTINUE_TRANSFER,
    SS_COMPLETE_TRANSFER,
    SS_TERMINATE_SSH,
    SS_DISCONNECT,
    SS_AWAITING_ANSWER,
    SS_IDLE
} SyncState;

@interface Synchronizer : NSObject
    <UIAlertViewDelegate>
{
    SyncState state;

    NSTimer *timer;

    Project *project;
    ProjectFile *file;
    NSInteger nextFileOffset;
    NSMutableArray *projectsToSync;

    NSString *localHash;
    NSString *remoteHash;

    NSData *localContent;

    int sock;
    LIBSSH2_SESSION *session;
    CommandDispatcher *dispatcher;
    FileTransfer *transfer;
    FileLister *lister;
    struct sockaddr_in sin;

    CommandDispatcher *currentCommand;
    NSMutableArray *pendingCommands;

    bool startup;

    struct {
        bool password;
        bool interactive;
        bool publickey;
    } authType;
}

@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSMutableArray *projectsToSync;
@property (nonatomic, retain) ProjectFile *file;
@property (nonatomic, retain) CommandDispatcher *dispatcher;
@property (nonatomic, retain) FileTransfer *transfer;
@property (nonatomic, retain) FileLister *lister;
@property (nonatomic, retain) CommandDispatcher *currentCommand;

- (SyncState) state;
- (void) step;
- (void) stop;
- (void) synchronize;
- (void) synchronize:(NSNumber *)projectNumber;
- (void) appendCommand:(CommandDispatcher *)command;

@end
