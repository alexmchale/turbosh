#import "ProjectFileSelector.h"

@implementation ProjectFileSelector

@synthesize myTableView;
@synthesize project;
@synthesize allFiles, syncFiles, removedFiles, shownFiles;
@synthesize mode;

#pragma mark Button Actions

- (void) saveAction
{
    if (busy) return;

    ProjectFile *file = [[ProjectFile alloc] init];

    for (NSString *filename in syncFiles) {
        [file loadByProject:project filename:filename forUsage:mode];
        if (file.num == nil) [Store storeProjectFile:file];
    }

    for (NSString *filename in removedFiles) {
        [file loadByProject:project filename:filename forUsage:mode];
        if (file.num != nil) [Store deleteProjectFile:file];
    }

    [file release];

    [TurboshAppDelegate sync:project.num];
    [TurboshAppDelegate reloadList];
    [TurboshAppDelegate editProject:project];
}

- (void) cancelAction {
    if (busy) return;

    [TurboshAppDelegate editProject:project];
}

#pragma mark View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    busy = true;

    [super viewDidAppear:animated];

    NSString *error = nil;

    MBProgressHUD *hud = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
    hud.labelText = @"Loading Files";
    [self.view addSubview:hud];
    [hud show:YES];

    Shell *shell = [[Shell alloc] initWithProject:project];

    if ([shell connect]) {
        self.allFiles = [shell files:mode];
        self.shownFiles = allFiles;

        if (self.allFiles) {
            self.syncFiles = [NSMutableArray arrayWithArray:[Store filenames:project ofUsage:mode]];
            self.removedFiles = [NSMutableArray array];
            [myTableView reloadData];
        } else {
            error = @"Failed to get list of files.";
        }

        [shell disconnect];
    } else {
        error = @"Failed to connect to server.";
    }

    [shell release];

    if (error) {
        self.allFiles = nil;
        self.syncFiles = nil;
        self.shownFiles = nil;
    }

    [hud hide:YES];
    [hud removeFromSuperview];

    if (allFiles == nil || error != nil)
        show_alert(@"Connection Failed", error);

    busy = false;
}

- (void) viewDidDisappear:(BOOL)animated {
    self.allFiles = nil;
    self.syncFiles = nil;
    self.removedFiles = nil;
    self.shownFiles = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (mode) {
        case FU_FILE: return @"Files to synchronize to Turbosh";
        case FU_PATH: return @"Directories to synchronize to Turbosh";
        case FU_TASK: return @"Executables to run from Turbosh";

        default: assert(false); return nil;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (mode) {
        case FU_FILE: return @"The selected files will be synchronized with the server.";
        case FU_PATH: return @"All existing and new files in the selected paths will be synchronized.";
        case FU_TASK: return @"Any files with executable permission in your project are available as tasks.";

        default: assert(false); return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return shownFiles ? [shownFiles count] : 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    // Configure the cell...
    assert(shownFiles);
    NSString *file = [shownFiles objectAtIndex:indexPath.row];
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
    NSString *file = [self.shownFiles objectAtIndex:indexPath.row];

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
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    project = nil;
    allFiles = nil;
    syncFiles = nil;
    removedFiles = nil;
    shownFiles = nil;

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

    return self;
}

- (void)dealloc {
    [myTableView release];
    [project release];
    [allFiles release];
    [syncFiles release];
    [shownFiles release];
    [removedFiles release];
    [cancelButton release];
    [spacer release];
    [saveButton release];

    [super dealloc];
}

#pragma mark Alert View Delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [TurboshAppDelegate editProject:project];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    [toolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, saveButton, nil]];
}

#pragma mark Search Bar Delegate

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText == nil || [searchText length] == 0) {
        self.shownFiles = allFiles;
        [myTableView reloadData];
        return;
    }

    NSMutableArray *newlyShownFiles = [NSMutableArray array];
    NSString *lowercaseSearchText = [searchText lowercaseString];

    for (NSString *filename in allFiles) {
        NSString *lowercaseFilename = [filename lowercaseString];
        NSRange textRange = [lowercaseFilename rangeOfString:lowercaseSearchText];

        if (textRange.location != NSNotFound) {
            [newlyShownFiles addObject:filename];
        }
    }

    self.shownFiles = newlyShownFiles;
    [myTableView reloadData];
}

@end

