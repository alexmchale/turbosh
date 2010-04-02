#import "ProjectFileSelector.h"

@implementation ProjectFileSelector

@synthesize myTableView, project, allFiles, syncFiles;
@synthesize cancelButton, spacer, saveButton;

#pragma mark Button Actions

- (void) saveAction {
    for (NSString *filename in syncFiles) {
        ProjectFile *file = [Store projectFile:project filename:filename];
        
        if (file == nil) {
            file = [[[ProjectFile alloc] initByProject:project filename:filename] autorelease];
            [Store storeProjectFile:file];
        }
    }
    
    [SwiftCodeAppDelegate editProject:project];
}

- (void) cancelAction {
    [SwiftCodeAppDelegate editProject:project];
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
        self.allFiles = [shell files];
        
        if (self.allFiles) {
            self.syncFiles = [NSMutableArray arrayWithArray:[Store filenames:project]];
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
}

- (void) viewDidDisappear:(BOOL)animated {
    self.allFiles = nil;
    self.syncFiles = nil;
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


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *file = [self.allFiles objectAtIndex:indexPath.row];
    
    if ([syncFiles containsObject:file])
        [syncFiles removeObject:file];
    else
        [syncFiles addObject:file];
    
    [tableView reloadData];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];    
}

#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.cancelButton = nil;
    self.spacer = nil;
    self.saveButton = nil;
}

- (void)dealloc {
    [super dealloc];
    [myTableView release];
    [project release];
    [allFiles release];
    [syncFiles release];
    [cancelButton release];
    [spacer release];
    [saveButton release];
}

#pragma mark Alert View Delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [SwiftCodeAppDelegate editProject:project];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
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
    
    NSMutableArray *a = [NSMutableArray arrayWithObjects:cancelButton, spacer, saveButton, nil];
    [toolbar setItems:a];
}

@end

