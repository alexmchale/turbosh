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
