#import "ProjectSettingsController.h"
#import "ProjectTaskManager.h"

@implementation ProjectSettingsController

@synthesize myTableView;
@synthesize projectName;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;
@synthesize syncLabel;

#pragma mark Action Management

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

    [TurboshAppDelegate editProject:nextProject];

    [nextProject release];
}

- (void) removeThisProject
{
    assert(proj);

    [Store deleteProject:proj];
    [proj release];
    proj = nil;

    if ([Store projectCount] == 0) {
        [self addNewProject];
    } else {
        Project *nextProject = [[Project alloc] init];

        nextProject.num = [Store projectNumAtOffset:0];
        [Store loadProject:nextProject];

        [TurboshAppDelegate editProject:nextProject];

        [nextProject release];
    }
}

- (void) updateStatus:(NSNotification *)notif
{
    enum SyncState state = [[notif.userInfo valueForKey:@"state"] intValue];
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

- (void) resetPublicKey
{
    [[[[KeyPair alloc] init] generate] release];
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
    [myTableView reloadData];
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
        default:                    assert(false);
    }

    return 0;
}

- (UITableViewCell *) cellFor:(UITableView *)tableView
						field:(UITextField *)field
						 name:(NSString *)name
						value:(NSString *)value
{
    static NSString *CellIdentifier = @"ProjectSettingsTextFieldCellIdentifier";

    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:CellIdentifier] autorelease];
    }

    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }

    CGRect tableFrame = tableView.frame;
    int yOffset = 10;
    int height = cell.frame.size.height - (2 * yOffset);

    UILabel *label = [[UILabel alloc] init];
    label.text = name;
    label.frame = CGRectMake(10, yOffset, 90, height);
    label.font = [UIFont boldSystemFontOfSize:14.0];
    label.textAlignment = UITextAlignmentRight;
    label.backgroundColor = [UIColor clearColor];

    field.text = value;
    field.frame = CGRectMake(110, yOffset, tableFrame.size.width - 220, height);
    field.textColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1.0];

    [cell.contentView addSubview:label];
    [cell.contentView addSubview:field];

    [label release];

    return cell;
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
            cell = [tableView dequeueReusableCellWithIdentifier:@"FilesCell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:@"FilesCell"] autorelease];
            }

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
            cell = [tableView dequeueReusableCellWithIdentifier:@"AddRemCell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:@"AddRemCell"] autorelease];
            }

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
            cell = [tableView dequeueReusableCellWithIdentifier:@"pkCell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:@"pkCell"] autorelease];
            }

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

            ProjectFileSelector *pfs = [[ProjectFileSelector alloc]
                                        initWithNibName:@"ProjectFileSelector"
                                        bundle:nil];
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

            [TurboshAppDelegate switchTo:pfs];
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

                    UIActionSheet *actionSheet =
                        [[UIActionSheet alloc]
                         initWithTitle:act
                         delegate:self
                         cancelButtonTitle:@"Nevermind"
                         destructiveButtonTitle:@"Remove it!"
                         otherButtonTitles:nil];

                    actionSheet.tag = TAG_DELETE_PROJECT;
                    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                    [actionSheet showInView:self.view];

                    [actionSheet release];
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
                {
                    NSString *act =
                    [NSString
                     stringWithFormat:@"Are you sure you want to generate a new SSH key?",
                     proj.name];

                    UIActionSheet *actionSheet =
                    [[UIActionSheet alloc]
                     initWithTitle:act
                     delegate:self
                     cancelButtonTitle:@"Nevermind"
                     destructiveButtonTitle:@"Reset it!"
                     otherButtonTitles:nil];

                    actionSheet.tag = TAG_RESET_KEY;
                    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                    [actionSheet showInView:self.view];

                    [actionSheet release];
                }   break;

                default: assert(false);
            }

        }   break;

        default: assert(false);
    }

}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TS_SUBSCRIPTION && indexPath.row == TS_MANAGE_TASKS) {
        ProjectTaskManager *ptm = [[ProjectTaskManager alloc] initWithStyle:UITableViewStyleGrouped];
        [TurboshAppDelegate switchTo:ptm];
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
