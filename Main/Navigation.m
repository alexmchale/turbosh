void switch_to_controller(UIViewController<ContentPaneDelegate> *controller)
{
    [DELEGATE.detailViewController switchTo:controller];
}

void switch_to_edit_project(Project *project)
{
    ProjectSettingsController *psc = DELEGATE.projectSettingsController;

    if (psc == nil) {
        if (IS_IPAD)
            psc = [[ProjectSettingsController alloc] initWithNibName:@"ProjectSettingsController-iPad" bundle:nil];
        else
            psc = [[ProjectSettingsController alloc] initWithNibName:@"ProjectSettingsController-iPhone" bundle:nil];

        DELEGATE.projectSettingsController = psc;
        [psc release];
    }

    DELEGATE.rootViewController.title = project.name;
    [psc setProject:project];
    [Store setCurrentProject:project];

    switch_to_controller(psc);
}

void switch_to_edit_current_project()
{
    Project *currentProject = [Project current];
    switch_to_edit_project(currentProject);
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
