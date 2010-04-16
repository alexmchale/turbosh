#import "Synchronizer.h"

#define SYNCHRONIZE_DELAY_SECONDS 0.25


@implementation Synchronizer

@synthesize timer;
@synthesize project, file;

#pragma mark Synchronizer

- (void) selectProject
{
}

- (void) connectToServer
{
}

- (void) selectFile
{
}

- (void) initiateHash
{
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

- (void) step
{
    if (project == nil) state = SS_SELECT_PROJECT;
    
    switch (state) {
        case SS_SELECT_PROJECT:         return [self selectProject];
        case SS_CONNECT_TO_SERVER:      return [self connectToServer];
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
