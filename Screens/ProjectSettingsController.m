#import "ProjectSettingsController.h"
#import "ProjectTaskManager.h"

@implementation ProjectSettingsController

@synthesize myTableView;
@synthesize projectName;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;
@synthesize syncLabel;

#pragma mark Action Management

- (NSIndexPath *) indexOfField:(UITextField *)textField
{
    int section = TS_SSH_CREDENTIALS;
    int row = 999;

    if (textField == projectName.text) {
        section = TS_PROJECT_MAIN;
        row = TM_NAME;
    }

    if (textField == sshHost.text) row = TC_HOSTNAME;
    if (textField == sshPort.text) row = TC_PORT;
    if (textField == sshUser.text) row = TC_USERNAME;
    if (textField == sshPass.text) row = TC_PASSWORD;
    if (textField == sshPath.text) row = TC_PATH;

    if (row == 999)
        return nil;

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void) addNewProject
{
    Project *nextProject = [[Project alloc] init];

    nextProject.name = @"New Project";

    if (proj) {
        nextProject.sshHost = proj.sshHost;
        nextProject.sshPort = proj.sshPort;
        nextProject.sshUser = proj.sshUser;
        nextProject.sshPass = proj.sshPass;
        nextProject.sshPath = proj.sshPath;
    }

    [Store storeProject:nextProject];
    [myTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

    switch_to_edit_project(nextProject);

    [nextProject release];
}

- (void) removeThisProject
{
    assert(proj);

    [Store deleteProject:proj];
    [proj release];
    proj = nil;

    [myTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

    if ([Store projectCount] == 0) {
        [self addNewProject];
    } else {
        Project *nextProject = [[Project alloc] init];

        nextProject.num = [Store projectNumAtOffset:0];
        [Store loadProject:nextProject];

        switch_to_edit_project(nextProject);

        [nextProject release];
    }
}

- (void) updateStatus:(NSNotification *)notif
{
    SyncState state = [[notif.userInfo valueForKey:@"state"] intValue];
    Project *p = [notif.userInfo valueForKey:@"project"];
    ProjectFile *f = [notif.userInfo valueForKey:@"file"];
    CommandDispatcher *d = [notif.userInfo valueForKey:@"task"];
    NSString *t = nil;

    switch (state) {
        case SS_SELECT_PROJECT:
            t = @"Selecting project to synchronize";
            break;

        case SS_BEGIN_CONN:
        case SS_ESTABLISH_CONN:
        case SS_ESTABLISH_SSH:
        case SS_REQUEST_AUTH_TYPE:
        case SS_AUTHENTICATE_SSH_BY_KEY:
        case SS_AUTHENTICATE_SSH_BY_PASSWORD:
            t = [NSString stringWithFormat:@"Connecting to %@", [p name]];
            break;

        case SS_EXECUTE_COMMAND:
            t = [NSString stringWithFormat:@"Executing %@ on %@", [d command], [p name]];
            break;

        case SS_SELECT_FILE:
        case SS_INITIATE_LIST:
            break;

        case SS_CONTINUE_LIST:
        case SS_INITIATE_HASH:
        case SS_CONTINUE_HASH:
        case SS_COMPLETE_HASH:
            t = [NSString stringWithFormat:@"Synchronizing %@ on %@", [f condensedPath], [p name]];
            break;

        case SS_FILE_IS_MISSING:
        case SS_DELETE_LOCAL_FILE:
        case SS_TEST_IF_CHANGED:
            break;

        case SS_INITIATE_UPLOAD:
            t = [NSString stringWithFormat:@"Uploading %@ to %@", [f condensedPath], p.name];
            break;

        case SS_INITIATE_DOWNLOAD:
            t = [NSString stringWithFormat:@"Downloading %@ from %@", [f condensedPath], p.name];
            break;

        case SS_CONTINUE_TRANSFER:
        case SS_COMPLETE_TRANSFER:
            break;

        case SS_TERMINATE_SSH:
        case SS_DISCONNECT:
            t = [NSString stringWithFormat:@"Disconnecting from %@", p.name];
            break;

        case SS_AWAITING_ANSWER:
            break;

        case SS_IDLE:
            t = @"Turbosh is currently idle";
            break;

        default: assert(false);
    }

    if (t) syncLabel.text = t;
}

#pragma mark Manage Public Key

- (BOOL) resignFirstResponder
{
    [super resignFirstResponder];

    [projectName resignFirstResponder];
    [sshHost resignFirstResponder];
    [sshPort resignFirstResponder];
    [sshUser resignFirstResponder];
    [sshPass resignFirstResponder];
    [sshPath resignFirstResponder];

    [self saveForm];

    return YES;
}

- (void) copyPublicKey
{
    KeyPair *key = [[KeyPair alloc] init];
    NSString *publicKey = [NSString stringWithContentsOfFile:[key publicFilename]
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:publicKey];
    [key release];
}

- (void) sendPublicKey
{
    TurboshAppDelegate *app = [[UIApplication sharedApplication] delegate];
    KeyPair *key = [[KeyPair alloc] init];
    NSString *publicKey = [NSString stringWithContentsOfFile:[key publicFilename]
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    MFMailComposeViewController *con = [[MFMailComposeViewController alloc] init];

    con.mailComposeDelegate = self;
    con.navigationBar.barStyle = UIBarStyleBlack;
    [con setSubject:@"Turbosh Public Key"];
    [con setMessageBody:publicKey isHTML:NO];

    if (app.splitViewController)
        [app.splitViewController presentModalViewController:con animated:YES];
    else
        [app.detailViewController presentModalViewController:con animated:YES];

    [con release];
    [key release];
}

- (void) sendLogFile
{
    TurboshAppDelegate *app = [[UIApplication sharedApplication] delegate];
    NSString *logContents = [NSString stringWithContentsOfFile:user_file_path(@"console.log")
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    MFMailComposeViewController *con = [[MFMailComposeViewController alloc] init];

    con.mailComposeDelegate = self;
    con.navigationBar.barStyle = UIBarStyleBlack;
    [con setToRecipients:[NSArray arrayWithObject:@"turbosh@anticlever.com"]];
    [con setSubject:@"Turbosh Console Log"];
    [con setMessageBody:logContents isHTML:NO];

    if (app.splitViewController)
        [app.splitViewController presentModalViewController:con animated:YES];
    else
        [app.detailViewController presentModalViewController:con animated:YES];

    [con release];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error
{
    TurboshAppDelegate *app = [[UIApplication sharedApplication] delegate];

    if (app.splitViewController)
        [app.splitViewController dismissModalViewControllerAnimated:YES];
    else
        [app.detailViewController dismissModalViewControllerAnimated:YES];
}

- (void) promptForResetPublicKey
{
    NSString *act =
        [NSString
         stringWithFormat:@"Are you sure you want to generate a new SSH key?",
         proj.name];

    show_action_sheet(self, TAG_RESET_KEY, act, @"Nevermind", @"Reset it!");
}

- (void) resetPublicKey
{
    KeyPair *key = [[KeyPair alloc] init];
    [key generate];
    [key release];
}

#pragma mark View Initialization

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [TurboshAppDelegate reloadList];
    [myTableView reloadData];

    // Update the title bar.
    [TurboshAppDelegate setLabelText:@"Project Settings"];

    // Listen for sync events.

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    Synchronizer *sync = [TurboshAppDelegate synchronizer];

    [nc addObserver:self
           selector:@selector(updateStatus:)
               name:@"sync-state"
             object:sync];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Stop listening for sync events.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self resignFirstResponder];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resignFirstResponder];

    [myTableView reloadData];

    [projectName adjustSizeFor:myTableView];
    [sshHost adjustSizeFor:myTableView];
    [sshPort adjustSizeFor:myTableView];
    [sshUser adjustSizeFor:myTableView];
    [sshPass adjustSizeFor:myTableView];
    [sshPath adjustSizeFor:myTableView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) viewDidLoad
{
    self.projectName = [TextFieldCell cellForTableView:myTableView labeled:@"Name"];
    self.projectName.text.delegate = self;
    [self.projectName setValue:proj.name];

    self.sshHost = [TextFieldCell cellForTableView:myTableView labeled:@"Hostname"];
    self.sshHost.text.delegate = self;
    [self.sshHost setValue:proj.sshHost];

    self.sshPort = [TextFieldCell cellForTableView:myTableView labeled:@"Port"];
    self.sshPort.text.delegate = self;
    self.sshPort.text.keyboardType = UIKeyboardTypeNumberPad;
    [self.sshPort setValue:(proj.sshPort ? [proj.sshPort stringValue] : @"22")];

    self.sshUser = [TextFieldCell cellForTableView:myTableView labeled:@"Username"];
    self.sshUser.text.delegate = self;
    [self.sshUser setValue:proj.sshUser];

    self.sshPass = [TextFieldCell cellForTableView:myTableView labeled:@"Password"];
    self.sshPass.text.delegate = self;
    self.sshPass.text.secureTextEntry = YES;
    [self.sshPass setValue:proj.sshPass];

    self.sshPath = [TextFieldCell cellForTableView:myTableView labeled:@"Path"];
    self.sshPath.text.delegate = self;
    [self.sshPath setValue:proj.sshPath];
}

- (void) viewDidUnload
{
    self.projectName = nil;
    self.sshHost = nil;
    self.sshPort = nil;
    self.sshUser = nil;
    self.sshPass = nil;
    self.sshPath = nil;
}

- (void)dealloc {
    [myTableView release];
    [proj release];
    [projectName release];
    [sshHost release];
    [sshPort release];
    [sshUser release];
    [sshPass release];
    [sshPath release];

    [super dealloc];
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return TS_SECTION_COUNT;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:       return @"Project";
        case TS_SSH_CREDENTIALS:    return @"SSH Credentials";
        case TS_SUBSCRIPTION:       return @"Subscriptions";
        case TS_ADD_REM:            return @"Project Management";
        case TS_MANAGE_KEY:         return @"Public Key Authentication";
        case TS_SUPPORT:            return @"App Support";
        default:                    assert(false);
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:       return TM_ROW_COUNT;
        case TS_SSH_CREDENTIALS:    return TC_ROW_COUNT;
        case TS_SUBSCRIPTION:       return TS_ROW_COUNT;
        case TS_ADD_REM:            return proj.num ? TAR_ROW_COUNT : 0;
        case TS_MANAGE_KEY:         return TPK_ROW_COUNT;
        case TS_SUPPORT:            return SUPPORT_ROW_COUNT;
        default:                    assert(false);
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case TS_PROJECT_MAIN:
            switch (indexPath.row) {
                case TM_NAME:
                    cell = projectName;
                    break;

                default: assert(false);
            }
            break;

        case TS_SSH_CREDENTIALS:
            switch (indexPath.row) {
                case TC_HOSTNAME:
                    cell = sshHost;
                    break;

                case TC_PORT:
                    cell = sshPort;
                    break;

                case TC_USERNAME:
                    cell = sshUser;
                    break;

                case TC_PASSWORD:
                    cell = sshPass;
                    break;

                case TC_PATH:
                    cell = sshPath;
                    break;

                default: assert(false);
            }
            break;

        case TS_SUBSCRIPTION:
            cell = [tableView cellForId:@"FilesCell" withStyle:UITableViewCellStyleDefault];

            switch (indexPath.row) {
                case TS_MANAGE_FILES:
                    cell.textLabel.text = @"Synchronized Files";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case TS_MANAGE_PATHS:
                    cell.textLabel.text = @"Synchronized Paths";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case TS_MANAGE_TASKS:
                    cell.textLabel.text = @"Task Executables";
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    break;
            }

            break;

        case TS_ADD_REM:
            cell = [tableView cellForId:@"AddRemCell" withStyle:UITableViewCellStyleDefault];

            switch (indexPath.row) {
                case TAR_ADD_PROJECT:
                    cell.textLabel.text = @"Add New Project";
                    break;

                case TAR_REM_PROJECT:
                    cell.textLabel.text = @"Delete This Project";
                    break;

                default: assert(false);
            }

            break;

        case TS_MANAGE_KEY:
            cell = [tableView cellForId:@"pkCell" withStyle:UITableViewCellStyleDefault];

            switch (indexPath.row) {
                case TPK_CLIPBOARD_KEY:
                    cell.textLabel.text = @"Copy public key to clipboard";
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;

                case TPK_SEND_KEY:
                    cell.textLabel.text = @"Email public key";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;

                case TPK_RESET_KEY:
                    cell.textLabel.text = @"Generate a new key pair";
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;

                default: assert(false);
            }

            break;

        case TS_SUPPORT:
            cell = [tableView cellForId:@"spCell" withStyle:UITableViewCellStyleDefault];
            cell.accessoryType = UITableViewCellAccessoryNone;

            switch (indexPath.row) {
                case SUPPORT_EMAIL_CONSOLE_LOG:
                    cell.textLabel.text = @"Email Application Log";
                    break;

                default: assert(false);
            }

            break;

        default: assert(false);
    }

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case TS_PROJECT_MAIN:
            switch (indexPath.row) {
                case TM_NAME:
					[projectName becomeFirstResponder];
                    break;

                default: assert(false);
            }
            break;

        case TS_SSH_CREDENTIALS:
            switch (indexPath.row) {
                case TC_HOSTNAME:
					[sshHost becomeFirstResponder];
                    break;

                case TC_PORT:
					[sshPort becomeFirstResponder];
                    break;

                case TC_USERNAME:
					[sshUser becomeFirstResponder];
                    break;

                case TC_PASSWORD:
					[sshPass becomeFirstResponder];
                    break;

                case TC_PATH:
					[sshPath becomeFirstResponder];
                    break;

                default: assert(false);
            }
            break;

        case TS_SUBSCRIPTION:
        {
            [self resignFirstResponder];

            NSString *nib = IS_IPAD ? @"ProjectFileSelector-iPad" : @"ProjectFileSelector-iPhone";
            ProjectFileSelector *pfs = [[ProjectFileSelector alloc] initWithNibName:nib bundle:nil];
            pfs.project = proj;

            switch (indexPath.row) {
                case TS_MANAGE_FILES:
                    pfs.mode = FU_FILE;
                    break;

                case TS_MANAGE_PATHS:
                    pfs.mode = FU_PATH;
                    break;

                case TS_MANAGE_TASKS:
                    pfs.mode = FU_TASK;
                    break;
            }

            switch_to_controller(pfs);
            [pfs release];

            break;
        }

        case TS_ADD_REM:
        {
            [self resignFirstResponder];

            switch (indexPath.row) {
                case TAR_ADD_PROJECT:
                    [self addNewProject];
                    break;

                case TAR_REM_PROJECT:
                {
                    NSString *act =
                        [NSString
                         stringWithFormat:@"Are you sure you want to remove the project %@ from Turbosh?",
                         proj.name];

                    show_action_sheet(self, TAG_DELETE_PROJECT, act, @"Nevermind", @"Remove it!");
                }   break;

                default: assert(false);
            }
        }   break;

        case TS_MANAGE_KEY:
        {
            switch (indexPath.row) {
                case TPK_CLIPBOARD_KEY:
                    [self copyPublicKey];
                    break;

                case TPK_SEND_KEY:
                    [self sendPublicKey];
                    break;

                case TPK_RESET_KEY:
                    [self promptForResetPublicKey];
                    break;

                default: assert(false);
            }

        }   break;

        case TS_SUPPORT:
        {
            switch (indexPath.row) {
                case SUPPORT_EMAIL_CONSOLE_LOG:
                    [self sendLogFile];
                    break;

                default: assert(false);
            }

            break;
        }

        default: assert(false);
    }

}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TS_SUBSCRIPTION && indexPath.row == TS_MANAGE_TASKS) {
        ProjectTaskManager *ptm = [[ProjectTaskManager alloc] initWithStyle:UITableViewStyleGrouped];
        switch_to_controller(ptm);
        [ptm release];
    }
}

#pragma mark Action Sheet Delegate

// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == TAG_DELETE_PROJECT && buttonIndex == 0)
        [self removeThisProject];

    if (actionSheet.tag == TAG_RESET_KEY && buttonIndex == 0)
        [self resetPublicKey];
}

#pragma mark Text Field Delegate

- (void) saveForm
{
    if (!proj || !projectName) return;

	NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];

    proj.name = projectName.text.text;

    proj.sshHost = sshHost.text.text;

    NSString *portString = [sshPort.text.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!portString || [@"" isEqualToString:portString])
        proj.sshPort = [NSNumber numberWithInt:22];
    else
        proj.sshPort = [nf numberFromString:portString];
    if ([proj.sshPort intValue] <= 0) proj.sshPort = [NSNumber numberWithInt:22];

    proj.sshUser = sshUser.text.text;
    proj.sshPass = sshPass.text.text;
    proj.sshPath = sshPath.text.text;

    [Store storeProject:proj];

    [TurboshAppDelegate setMenuText:proj.name];

    [nf release];
}

- (void)selectIndexEvent:(NSTimer *)theTimer
{
    NSIndexPath *indexPath = theTimer.userInfo;

    if (indexPath) {
        [myTableView scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionMiddle
                                   animated:YES];
    }
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    adjust_current_controller();

    NSIndexPath *indexPath = [self indexOfField:textField];

    if (indexPath) {
        [myTableView scrollToRowAtIndexPath:indexPath
                           atScrollPosition:UITableViewScrollPositionMiddle
                                   animated:YES];

        [NSTimer scheduledTimerWithTimeInterval:0.50
                                         target:self
                                       selector:@selector(selectIndexEvent:)
                                       userInfo:indexPath
                                        repeats:NO];
    }
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    [self saveForm];

    if (textField == projectName.text) [TurboshAppDelegate reloadList];
}

#pragma mark Project Management

- (void) setProject:(Project *)newProject {
    [self saveForm];

    // Store the project in this form.

    [proj release];
    proj = newProject;
    [newProject retain];

    // Now update the fields in this form for the new project.

    projectName.text.text = proj.name;

    sshHost.text.text = proj.sshHost;
    sshPort.text.text = [proj.sshPort stringValue];
    sshUser.text.text = proj.sshUser;
    sshPass.text.text = proj.sshPass;
    sshPath.text.text = proj.sshPath;

    [myTableView reloadData];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
}

@end
