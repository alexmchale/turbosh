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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    // Configure the cell.
    cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     When a row is selected, set the detail view controller's detail item to the item associated with the selected row.
     */
    //    detailViewController.detailItem = [NSString stringWithFormat:@"Row %d", indexPath.row];
    //    
    //    DetailViewController *dvc = [[DetailViewController alloc] initWithNibName:nil bundle:nil];
    //    [detailViewController presentModalViewController:dvc animated:YES];
    //    [dvc release];
    

    //FileViewController *fvc = [[[FileViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    
    //[detailViewController switchTo:fvc];
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
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
    UIBarItem *spacer = [[[UIBarButtonItem alloc]
                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                          target:nil action:nil] autorelease];
    UIBarItem *save = [[[UIBarButtonItem alloc]
                        initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                        target:self action:@selector(saveProject)] autorelease];
    
    NSMutableArray *items = [[[toolbar items] mutableCopy] autorelease];
    [items addObject:spacer];
    [items addObject:save];
    [toolbar setItems:items animated:YES];
}

@end
