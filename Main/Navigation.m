#define DELEGATE ((TurboshAppDelegate *)[[UIApplication sharedApplication] delegate])

void switch_to_controller(UIViewController<ContentPaneDelegate> *controller)
{
    [DELEGATE.detailViewController switchTo:controller];
}

void switch_to_list()
{
    RootViewController *rvc = DELEGATE.rootViewController;

    if (rvc == nil) {
        rvc = [[[RootViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
        DELEGATE.rootViewController = rvc;
    }

    switch_to_controller(rvc);
}

void adjust_current_controller()
{
    [DELEGATE.detailViewController adjustCurrentController];
}
