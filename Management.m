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

NSString *read_user_file(NSString *filename)
{
    return [NSString stringWithContentsOfFile:user_file_path(filename)
                                     encoding:NSUTF8StringEncoding
                                        error:nil];
}

NSString *read_bundle_file(NSString *filename)
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *filePath = [bundle pathForResource:filename ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];

    return [[[NSString alloc] initWithContentsOfURL:fileURL] autorelease];
}

NSString *script_command(NSString *scriptName, NSDictionary *params)
{
    NSString *script = read_bundle_file(scriptName);
    
    for (NSString *key in params) {
        NSString *value = [[params objectForKey:key] stringValue];
        NSString *anchor = [NSString stringWithFormat:@"___%@___", key];
        script = [script stringByReplacingOccurrencesOfString:anchor withString:value];
    }
    
    script = [script stringByReplacingOccurrencesOfRegex:@"[\r\n]" withString:@" "];
    
    return script;
}
