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
    [Store storeProject:nextProject];

    [TurboshAppDelegate editProject:nextProject];

    [nextProject release];
}

- (void) removeThisProject
{
    assert(proj);

    [Store deleteProject:proj];

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
    KeyPair *key = [[KeyPair alloc] init];
    NSString *publicKey = [NSString stringWithContentsOfFile:[key publicFilename]
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    MFMailComposeViewController *con = [[MFMailComposeViewController alloc] init];

    con.mailComposeDelegate = self;
    con.navigationBar.barStyle = UIBarStyleBlack;
    [con setSubject:@"Turbosh Public Key"];
    [con setMessageBody:publicKey isHTML:NO];
    [self presentModalViewController:con animated:YES];

    [con release];
    [key release];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) resetPublicKey
{
    [[[[KeyPair alloc] init] generate] release];
}

#pragma mark View Initialization

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        proj = nil;

        projectName = [[UITextField alloc] init];
        projectName.autocorrectionType = UITextAutocorrectionTypeNo;
        projectName.autocapitalizationType = UITextAutocapitalizationTypeNone;
        projectName.delegate = self;
        projectName.clearButtonMode = UITextFieldViewModeWhileEditing;

        sshHost = [[UITextField alloc] init];
        sshHost.autocorrectionType = UITextAutocorrectionTypeNo;
        sshHost.autocapitalizationType = UITextAutocapitalizationTypeNone;
        sshHost.delegate = self;
        sshHost.clearButtonMode = UITextFieldViewModeWhileEditing;

        sshPort = [[UITextField alloc] init];
        sshPort.keyboardType = UIKeyboardTypeNumberPad;
        sshPort.delegate = self;
        sshPort.clearButtonMode = UITextFieldViewModeWhileEditing;

        sshUser = [[UITextField alloc] init];
        sshUser.autocorrectionType = UITextAutocorrectionTypeNo;
        sshUser.autocapitalizationType = UITextAutocapitalizationTypeNone;
        sshUser.delegate = self;
        sshUser.clearButtonMode = UITextFieldViewModeWhileEditing;

        sshPass = [[UITextField alloc] init];
        sshPass.secureTextEntry = YES;
        sshPass.autocorrectionType = UITextAutocorrectionTypeNo;
        sshPass.autocapitalizationType = UITextAutocapitalizationTypeNone;
        sshPass.delegate = self;
        sshPass.clearButtonMode = UITextFieldViewModeWhileEditing;

        sshPath = [[UITextField alloc] init];
        sshPath.autocorrectionType = UITextAutocorrectionTypeNo;
        sshPath.autocapitalizationType = UITextAutocapitalizationTypeNone;
        sshPath.delegate = self;
        sshPath.clearButtonMode = UITextFieldViewModeWhileEditing;

        syncLabel = nil;
    }
    return self;
}

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
					cell = [self cellFor:tableView field:projectName name:@"Name" value:proj.name];
                    break;

                default: assert(false);
            }
            break;

        case TS_SSH_CREDENTIALS:
            switch (indexPath.row) {
                case TC_HOSTNAME:
					cell = [self cellFor:tableView field:sshHost name:@"Hostname" value:proj.sshHost];
                    break;

                case TC_PORT:
					cell = [self cellFor:tableView field:sshPort name:@"Port" value:[proj.sshPort stringValue]];
                    break;

                case TC_USERNAME:
					cell = [self cellFor:tableView field:sshUser name:@"Username" value:proj.sshUser];
                    break;

                case TC_PASSWORD:
					cell = [self cellFor:tableView field:sshPass name:@"Password" value:proj.sshPass];
                    break;

                case TC_PATH:
					cell = [self cellFor:tableView field:sshPath name:@"Path" value:proj.sshPath];
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

    proj.name = projectName.text;

    proj.sshHost = sshHost.text;

    NSString *portString = [sshPort.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!portString || [@"" isEqualToString:portString])
        proj.sshPort = [NSNumber numberWithInt:22];
    else
        proj.sshPort = [nf numberFromString:portString];
    if ([proj.sshPort intValue] <= 0) proj.sshPort = [NSNumber numberWithInt:22];

    proj.sshUser = sshUser.text;
    proj.sshPass = sshPass.text;
    proj.sshPath = sshPath.text;

    [Store storeProject:proj];

    [TurboshAppDelegate setMenuText:proj.name];

    [nf release];
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    [self saveForm];

    if (textField == projectName) [TurboshAppDelegate reloadList];
}

#pragma mark Project Management

- (void) setProject:(Project *)newProject {
    [self saveForm];

    // Store the project in this form.

    proj = newProject;
    [newProject retain];

    // Now update the fields in this form for the new project.

    projectName.text = proj.name;

    sshHost.text = proj.sshHost;
    sshPort.text = [proj.sshPort stringValue];
    sshUser.text = proj.sshUser;
    sshPass.text = proj.sshPass;
    sshPath.text = proj.sshPath;

    [myTableView reloadData];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
}

@end
