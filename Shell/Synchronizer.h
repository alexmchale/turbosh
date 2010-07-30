#import <Foundation/Foundation.h>

typedef enum
{
    SS_SELECT_PROJECT,                  // 0
    SS_BEGIN_CONN,                      // 1
    SS_ESTABLISH_CONN,                  // 2
    SS_ESTABLISH_SSH,                   // 3
    SS_REQUEST_AUTH_TYPE,               // 4
    SS_AUTHENTICATE_SSH_BY_KEY,         // 5
    SS_AUTHENTICATE_SSH_BY_PASSWORD,    // 6
    SS_EXECUTE_COMMAND,                 // 7
    SS_INITIATE_LIST,                   // 8
    SS_CONTINUE_LIST,                   // 9
    SS_SELECT_FILE,                     // 10
    SS_INITIATE_HASH,                   // 11
    SS_CONTINUE_HASH,                   // 12
    SS_COMPLETE_HASH,                   // 13
    SS_FILE_IS_MISSING,                 // 14
    SS_DELETE_LOCAL_FILE,               // 15
    SS_TEST_IF_CHANGED,                 // 16
    SS_INITIATE_UPLOAD,                 // 17
    SS_INITIATE_DOWNLOAD,               // 18
    SS_CONTINUE_TRANSFER,               // 19
    SS_COMPLETE_TRANSFER,               // 20
    SS_TERMINATE_SSH,                   // 21
    SS_DISCONNECT,                      // 22
    SS_AWAITING_ANSWER,                 // 23
    SS_IDLE                             // 24
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
