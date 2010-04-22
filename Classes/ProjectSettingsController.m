#import "ProjectSettingsController.h"

@implementation ProjectSettingsController

@synthesize myTableView;
@synthesize proj;
@synthesize projectName;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;

#pragma mark Action Management

- (void) addNewProject
{
    Project *nextProject = [[Project alloc] init];

    nextProject.name = @"New Project";
    [Store storeProject:nextProject];

    [SwiftCodeAppDelegate editProject:nextProject];

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
        assert([Store loadProject:nextProject]);

        [SwiftCodeAppDelegate editProject:nextProject];

        [nextProject release];
    }

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

		sshHost = [[UITextField alloc] init];
		sshHost.autocorrectionType = UITextAutocorrectionTypeNo;
		sshHost.autocapitalizationType = UITextAutocapitalizationTypeNone;
		sshHost.delegate = self;

		sshPort = [[UITextField alloc] init];
		sshPort.keyboardType = UIKeyboardTypeNumberPad;
		sshPort.delegate = self;

		sshUser = [[UITextField alloc] init];
		sshUser.autocorrectionType = UITextAutocorrectionTypeNo;
		sshUser.autocapitalizationType = UITextAutocapitalizationTypeNone;
		sshUser.delegate = self;

		sshPass = [[UITextField alloc] init];
		sshPass.secureTextEntry = YES;
		sshPass.autocorrectionType = UITextAutocorrectionTypeNo;
		sshPass.autocapitalizationType = UITextAutocapitalizationTypeNone;
		sshPass.delegate = self;

		sshPath = [[UITextField alloc] init];
		sshPath.autocorrectionType = UITextAutocorrectionTypeNo;
		sshPath.autocapitalizationType = UITextAutocapitalizationTypeNone;
		sshPath.delegate = self;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [SwiftCodeAppDelegate reloadList];
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
        case TS_FILES:              return @"";
        case TS_TASKS:              return @"";
        case TS_ADD_REM:            return @"";
        default:                    assert(false);
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:       return TM_ROW_COUNT;
        case TS_SSH_CREDENTIALS:    return TC_ROW_COUNT;
        case TS_FILES:              return TF_ROW_COUNT;
        case TS_TASKS:              return TT_ROW_COUNT;
        case TS_ADD_REM:            return proj.num ? TAR_ROW_COUNT : 0;
        default:                    assert(false);
    }
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
    field.frame = CGRectMake(110, yOffset, tableFrame.size.width - 250, height);
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

        case TS_FILES:
            cell = [tableView dequeueReusableCellWithIdentifier:@"FilesCell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:@"FilesCell"] autorelease];
            }

            cell.textLabel.text = @"Synchronized Files";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            break;

        case TS_TASKS:
            cell = [tableView dequeueReusableCellWithIdentifier:@"TasksCell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                               reuseIdentifier:@"TasksCell"] autorelease];
            }

            cell.textLabel.text = @"Task Executables";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

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

        case TS_FILES:
        {
            ProjectFileSelector *pfs = [[ProjectFileSelector alloc]
                                         initWithNibName:@"ProjectFileSelector"
                                         bundle:nil];
            pfs.project = proj;

            [SwiftCodeAppDelegate switchTo:pfs];
            [pfs release];

        }   break;

        case TS_ADD_REM:
        {
            switch (indexPath.row) {
                case TAR_ADD_PROJECT:
                    [self addNewProject];
                    break;

                case TAR_REM_PROJECT:
                    [self removeThisProject];
                    break;

                default: assert(false);
            }
        }   break;

        default: assert(false);
    }

}

#pragma mark Text Field Delegate

- (void) saveForm
{
    if (!proj) return;

	NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];

    proj.name = projectName.text;

    proj.sshHost = sshHost.text;

    NSString *portString = [sshPort.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!portString || [@"" isEqualToString:portString])
        proj.sshPort = [NSNumber numberWithInt:22];
    else
        proj.sshPort = [nf numberFromString:portString];

    proj.sshUser = sshUser.text;
    proj.sshPass = sshPass.text;
    proj.sshPath = sshPath.text;

    [Store storeProject:proj];

    [nf release];
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    [self saveForm];

    if (textField == projectName) [SwiftCodeAppDelegate reloadList];
}

#pragma mark Project Management

- (void) setProject:(Project *)newProject {
    // Store the project in this form.

    proj = newProject;
    [newProject retain];

    // Now update the fields in this form for the new project.

    [myTableView reloadData];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
}

@end
