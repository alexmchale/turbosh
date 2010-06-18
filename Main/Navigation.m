void switch_to_list()
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    RootViewController *rvc = delegate.rootViewController;

    if (rvc == nil) {
        rvc = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        delegate.rootViewController = rvc;
    }

    [TurboshAppDelegate switchTo:rvc];
}
