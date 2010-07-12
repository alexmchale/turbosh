void synchronizer_stop()
{
    Synchronizer *sync = [TurboshAppDelegate synchronizer];

    [sync stop];
}

void synchronizer_start()
{
    Synchronizer *sync = [TurboshAppDelegate synchronizer];

    [sync synchronize];
}

// Run an entire synchronization loop.
void synchronizer_run()
{
    Synchronizer *sync = [[Synchronizer alloc] init];

    do {
        [sync step];
    } while ([sync state] != SS_IDLE);

    [sync release];
}

NSString *user_file_path(NSString *filename)
{
    NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [searchPath objectAtIndex:0];

    return [documentsPath stringByAppendingPathComponent:filename];
}
