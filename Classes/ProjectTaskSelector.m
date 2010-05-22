#import "ProjectTaskSelector.h"

@implementation ProjectTaskSelector

@synthesize myTableView, project, allFiles, syncFiles, removedFiles;
@synthesize myToolbar, savedToolbarItems;
@synthesize cancelButton, spacer, saveButton;

#pragma mark Button Actions

- (void) saveAction {
    ProjectFile *file = [[ProjectFile alloc] init];

    for (NSString *filename in syncFiles) {
        file.num = [Store projectTaskNumber:project filename:filename];
        file.project = project;
        file.filename = filename;

        if (!file.num) [Store storeProjectTask:file];
    }

    for (NSString *filename in removedFiles) {
        file.num = [Store projectTaskNumber:project filename:filename];
        file.project = project;

        if (file.num) [Store deleteProjectFile:file];
    }

    [file release];

    [myToolbar setItems:savedToolbarItems];

    [TurboshAppDelegate reloadList];
    [TurboshAppDelegate editProject:project];
}

- (void) cancelAction {
    [myToolbar setItems:savedToolbarItems];

    [TurboshAppDelegate editProject:project];
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *error = nil;

    MBProgressHUD *hud = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    hud.labelText = @"Loading Files";
    [self.view addSubview:hud];
    [hud show:YES];

    Shell *shell = [[Shell alloc] initWithProject:project];

    if ([shell connect]) {
        self.allFiles = [shell executables];

        if (self.allFiles) {
            self.syncFiles = [NSMutableArray arrayWithArray:[Store taskNames:project]];
            self.removedFiles = [NSMutableArray array];
            [myTableView reloadData];
        } else {
            error = @"Failed to get list of files.";
        }
    } else {
        error = @"Failed to connect to server.";
    }

    if (error) {
        self.allFiles = nil;
        self.syncFiles = nil;
    }

    [hud hide:YES];
    [hud removeFromSuperview];

    if (allFiles == nil || error != nil) {
        UIAlertView *alert =
        [[UIAlertView alloc]
         initWithTitle:@"Connection Failed"
         message:error
         delegate:self
         cancelButtonTitle:@"Okay"
         otherButtonTitles:nil];

        [alert show];
        [alert release];
    }

    [myTableView reloadData];
}

- (void) viewDidDisappear:(BOOL)animated {
    self.allFiles = nil;
    self.syncFiles = nil;
    self.removedFiles = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Executables to run from Turbosh";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Any files with executable permission in your project are available as tasks.";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (allFiles)
        return [allFiles count];
    else
        return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
    assert(allFiles);
    NSString *file = [allFiles objectAtIndex:indexPath.row];
    assert(file);

    cell.textLabel.text = file;

    if ([syncFiles containsObject:file])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *file = [self.allFiles objectAtIndex:indexPath.row];

    if ([syncFiles containsObject:file]) {
        [removedFiles addObject:file];
        [syncFiles removeObject:file];
    } else {
        [syncFiles addObject:file];
        [removedFiles removeObject:file];
    }

    [tableView reloadData];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Memory management

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    assert(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]);

    project = nil;
    allFiles = nil;
    syncFiles = nil;
    removedFiles = nil;
    savedToolbarItems = nil;

    return self;
}

- (void)viewDidUnload {
    self.cancelButton = nil;
    self.spacer = nil;
    self.saveButton = nil;
    self.myToolbar = nil;
    self.savedToolbarItems = nil;
}

- (void)dealloc {
    [myTableView release];
    [project release];
    [allFiles release];
    [syncFiles release];
    [removedFiles release];
    [cancelButton release];
    [spacer release];
    [saveButton release];
    [myToolbar release];
    [savedToolbarItems release];

    [super dealloc];
}

#pragma mark Alert View Delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [myToolbar setItems:savedToolbarItems];

    [TurboshAppDelegate editProject:project];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    self.myToolbar = toolbar;
    self.savedToolbarItems = [toolbar items];

    cancelButton =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
     target:self
     action:@selector(cancelAction)];

    spacer =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
     target:nil
     action:nil];

    saveButton =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemSave
     target:self
     action:@selector(saveAction)];

    NSArray *a = [NSArray arrayWithObjects:cancelButton, spacer, saveButton, nil];
    [toolbar setItems:a];
}

@end

