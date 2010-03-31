#import "ProjectSettingsController.h"

@implementation ProjectSettingsController

@synthesize proj;

#pragma mark View Initialization

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
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

typedef enum {
    TS_PROJECT_MAIN,
    TS_SSH_CREDENTIALS,
    TS_SECTION_COUNT
} TableSections;

typedef enum {
    TM_NAME,
    TM_ROW_COUNT
} TableMain;

typedef enum {
    TC_HOSTNAME,
    TC_PORT,
    TC_USERNAME,
    TC_PASSWORD,
    TC_PATH,
    TC_ROW_COUNT
} TableCredentials;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return TS_SECTION_COUNT;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:       return @"Project";
        case TS_SSH_CREDENTIALS:    return @"SSH Credentials";
        default:                    return nil;
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TS_PROJECT_MAIN:               return TM_ROW_COUNT;
        case TS_SSH_CREDENTIALS:            return TC_ROW_COUNT;
        default:                            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (indexPath.section) {
        case TS_PROJECT_MAIN:
            switch (indexPath.row) {
                case TM_NAME:
                    cell.textLabel.text = @"Name";
                    cell.detailTextLabel.text = proj.name;
                    break;
                    
                default: assert(false);
            }
            break;
            
        case TS_SSH_CREDENTIALS:
            switch (indexPath.row) {
                case TC_HOSTNAME:
                    cell.textLabel.text = @"Hostname";
                    cell.detailTextLabel.text = proj.sshHostname;
                    break;
                    
                case TC_PORT:
                    cell.textLabel.text = @"Port";
                    cell.detailTextLabel.text = @"";
                    break;
                    
                case TC_USERNAME:
                    cell.textLabel.text = @"Username";
                    cell.detailTextLabel.text = proj.sshUsername;
                    break;
                    
                case TC_PASSWORD:
                    cell.textLabel.text = @"Password";
                    cell.detailTextLabel.text = proj.sshPassword;
                    break;
                    
                case TC_PATH:
                    cell.textLabel.text = @"Path";
                    cell.detailTextLabel.text = proj.sshPath;
                    break;
                    
                default: assert(false);
            }
            break;
            
        default: assert(false);
    }

    return cell;
}

#pragma mark Table view delegate

- (void) engageEditField:(NSString *)fieldName value:(NSString *)fieldValue
{
    EditFieldController *etfc = [[[EditFieldController alloc] initWithNibName:nil bundle:nil] autorelease];
    etfc.returnTo = self;
    SwiftCodeAppDelegate *d = [[UIApplication sharedApplication] delegate];
    [d.detailViewController switchTo:etfc];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case TS_PROJECT_MAIN:
            switch (indexPath.row) {
                case TM_NAME:
                    [self engageEditField:@"Name" value:proj.name];
                    break;
                    
                default: assert(false);
            }
            break;
            
        case TS_SSH_CREDENTIALS:
            switch (indexPath.row) {
                case TC_HOSTNAME:
                    [self engageEditField:@"Hostname" value:proj.sshHostname];
                    break;
                    
                case TC_PORT:
                    [self engageEditField:@"Port" value:[proj.sshPort stringValue]];
                    break;
                    
                case TC_USERNAME:
                    [self engageEditField:@"Username" value:proj.sshUsername];
                    break;
                    
                case TC_PASSWORD:
                    [self engageEditField:@"Password" value:proj.sshPassword];
                    break;
                    
                case TC_PATH:
                    [self engageEditField:@"Path" value:proj.sshPath];
                    break;
                    
                default: assert(false);
            }
            break;
            
        default: assert(false);
    }
    
}

#pragma mark Project Management

- (void) setProject:(Project *)newProject {
    // Store the project in this form.
    
    proj = newProject;
    [newProject retain];
    
    // Now update the fields in this form for the new project.
}

- (void) saveProject {
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
