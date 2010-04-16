#import "Synchronizer.h"
#import <libssh2.h>
#import <arpa/inet.h>

#define SYNCHRONIZE_DELAY_SECONDS 0.25

@implementation Synchronizer

@synthesize timer;
@synthesize project, file;

#pragma mark Synchronizer

- (void) selectProject
{
    NSNumber *num = [Store projectNumAfterNum:project.num];

    self.file = nil;
    self.project = nil;
    nextFileOffset = 0;

    if (num == nil) return;

    self.project = [[Project alloc] init];
    [project release];

    self.project.num = num;

    assert([Store loadProject:project]);

    state = SS_CONNECT_TO_SERVER;
}

- (void) connectToServer
{
    struct sockaddr_in sin;

    // Verify that the current project has a server configured.
    if (!project || !project.sshHost || !project.sshPort ||
            !project.sshUser || !project.sshPass || !project.sshPath ||
            [project.sshHost length] == 0) {
        state = SS_SELECT_PROJECT;
        return;
    }

    // Create the new socket.
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        fprintf(stderr, "failed to create socket %d\n", errno);
        state = SS_SELECT_PROJECT;
        return;
    }

    // Set host parameters.
    sin.sin_family = AF_INET;
    sin.sin_port = htons([self.project.sshPort intValue]);
    sin.sin_addr.s_addr = inet_addr([self.project.sshHost UTF8String]);

    // Establish the TCP connection.
    if (connect(sock, (struct sockaddr *)&sin, sizeof(sin)) != 0) {
        fprintf(stderr, "failed to connect %d\n", errno);
        state = SS_DISCONNECT;
        return;
    }

    state = SS_ESTABLISH_SSH;
}

- (void) establishSsh
{
    if (session == NULL) {
        // Begin a new SSH session.

        session = libssh2_session_init();

        if (session == NULL) {
            state = SS_DISCONNECT;
            return;
        }

        // Configure LIBSSH2 for non-blocking communications.
        libssh2_session_set_blocking(session, 0);
    }

    // Establish the SSH connection.
    int rc = libssh2_session_startup(session, sock);

    if (rc == LIBSSH2_ERROR_EAGAIN) return;

    if (rc != 0) {
        fprintf(stderr, "Failure establishing SSH session: %d\n", rc);
        state = SS_TERMINATE_SSH;
        return;
    }

    state = SS_AUTHENTICATE_SSH;
}

- (void) authenticateSsh
{
    // Authenticate using the configured password.
    const char *user = [project.sshUser UTF8String];
    const char *pass = [project.sshPass UTF8String];

    int rc = libssh2_userauth_password(session, user, pass);

    if (rc == LIBSSH2_ERROR_EAGAIN) return;

    if (rc != 0) {
        fprintf(stderr, "Authentication by password failed.\n");
        state = SS_TERMINATE_SSH;
        return;
    }

    state = SS_SELECT_FILE;
}

- (void) selectFile
{
    self.file = [[ProjectFile alloc] init];
    [file release];

    self.file.num = [Store projectFileNumber:project atOffset:nextFileOffset];
    self.file.project = project;

    if (file.num == nil) {
        state = SS_TERMINATE_SSH;
        return;
    }

    assert([Store loadProjectFile:file]);

    state = SS_INITIATE_HASH;
}

- (void) initiateHash
{
    state = SS_TERMINATE_SSH;
}

- (void) continueHash
{
}

- (void) completeHash
{
}

- (void) testIfChanged
{
}

- (void) initiateUpload
{
}

- (void) continueUpload
{
}

- (void) completeUpload
{
}

- (void) initiateDownload
{
}

- (void) continueDownload
{
}

- (void) completeDownload
{
}

- (void) terminateSsh
{
    if (session != NULL) {
        libssh2_session_disconnect(session, "Normal Shutdown, Thank you for playing");
        libssh2_session_free(session);
        session = NULL;
    }

    state = SS_DISCONNECT;
}

- (void) disconnect
{
    close(sock);
    sock = 0;

    state = SS_SELECT_PROJECT;
}

- (void) step
{
    if (project == nil) state = SS_SELECT_PROJECT;

    switch (state) {
        case SS_SELECT_PROJECT:         return [self selectProject];
        case SS_CONNECT_TO_SERVER:      return [self connectToServer];
        case SS_ESTABLISH_SSH:          return [self establishSsh];
        case SS_AUTHENTICATE_SSH:       return [self authenticateSsh];
        case SS_SELECT_FILE:            return [self selectFile];
        case SS_INITIATE_HASH:          return [self initiateHash];
        case SS_CONTINUE_HASH:          return [self continueHash];
        case SS_COMPLETE_HASH:          return [self completeHash];
        case SS_TEST_IF_CHANGED:        return [self testIfChanged];
        case SS_INITIATE_UPLOAD:        return [self initiateUpload];
        case SS_CONTINUE_UPLOAD:        return [self continueUpload];
        case SS_COMPLETE_UPLOAD:        return [self completeUpload];
        case SS_INITIATE_DOWNLOAD:      return [self initiateDownload];
        case SS_CONTINUE_DOWNLOAD:      return [self continueDownload];
        case SS_COMPLETE_DOWNLOAD:      return [self completeDownload];
        case SS_TERMINATE_SSH:          return [self terminateSsh];
        case SS_DISCONNECT:             return [self disconnect];
    }
}

#pragma mark Memory Management

- (id) init
{
    assert(self = [super init]);

    timer = [NSTimer timerWithTimeInterval:SYNCHRONIZE_DELAY_SECONDS
                                    target:self
                                  selector:@selector(step)
                                  userInfo:nil
                                   repeats:YES];
    [timer retain];

    project = nil;
    file = nil;

    sock = 0;
    session = NULL;

    return self;
}

- (void) dealloc
{
    [timer release];
    [project release];
    [file release];

    [super dealloc];
}

@end
