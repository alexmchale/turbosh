#import "ProjectSettingsController.h"

@implementation ProjectSettingsController

@synthesize myTableView;
@synthesize proj;
@synthesize projectName;
@synthesize sshHost, sshPort, sshUser, sshPass, sshPath;

#pragma mark View Initialization

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
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
        default:                    assert(false);
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:       return TM_ROW_COUNT;
        case TS_SSH_CREDENTIALS:    return TC_ROW_COUNT;
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
	
	CGRect tableFrame = tableView.frame;
	int yOffset = 10;
	int height = cell.frame.size.height - (2 * yOffset);
	
	UILabel *label = [[[UILabel alloc] init] autorelease];
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
            
        default: assert(false);
    }

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
            
        default: assert(false);
    }
    
}

#pragma mark Text Field Delegate

- (void) textFieldDidEndEditing:(UITextField *)textField
{
	NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
	
	if (textField == projectName) proj.name = textField.text;
	
	if (textField == sshHost) proj.sshHost = textField.text;
	if (textField == sshPort) proj.sshPort = [nf numberFromString:textField.text];
	if (textField == sshUser) proj.sshUser = textField.text;
	if (textField == sshPass) proj.sshPass = textField.text;
	if (textField == sshPath) proj.sshPath = textField.text;
	
	[Store storeProject:proj];
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
//    UIBarItem *spacer = [[[UIBarButtonItem alloc]
//                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
//                          target:nil action:nil] autorelease];
//    UIBarItem *save = [[[UIBarButtonItem alloc]
//                        initWithBarButtonSystemItem:UIBarButtonSystemItemSave
//                        target:self action:@selector(saveProject)] autorelease];
//    
//    NSMutableArray *items = [[[toolbar items] mutableCopy] autorelease];
//    [items addObject:spacer];
//    [items addObject:save];
//    [toolbar setItems:items animated:YES];
}

@end
