//
//  RootViewController.m
//  SwiftCode
//
//  Created by Alex McHale on 3/24/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RootViewController.h"
#import "DetailViewController.h"


@implementation RootViewController

@synthesize detailViewController;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark Table view data source

typedef enum {
    MST_FILES,
    MST_TASKS,
    MST_PROJECTS,    
    MST_COUNT
} MenuSectionType;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return MST_COUNT;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case MST_FILES:     return @"Files";
        case MST_TASKS:     return @"Tasks";
        case MST_PROJECTS:  return @"Projects";
        default:            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MST_FILES:     return [Store fileCountForCurrentProject];
        case MST_TASKS:     return 0;
        case MST_PROJECTS:  return [Store projectCount];
        default:            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MenuCellIdentifier";
    Project *project = [[Project alloc] init];
    ProjectFile *file = [[ProjectFile alloc] init];
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    switch (indexPath.section) {
        case MST_FILES:
            [project loadCurrent];
            [file initByNumber:[Store projectFile:project atOffset:indexPath.row]];
            cell.textLabel.text = [file condensedPath];
            break;
            
        case MST_TASKS:
            break;
            
        case MST_PROJECTS:
            [project loadByOffset:indexPath.row];
            cell.textLabel.text = project.name;
            break;
    }

    [file release];
    [project release];
    
    return cell;

}

#pragma mark -
#pragma mark Table view delegate

- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SwiftCodeAppDelegate *d = [[UIApplication sharedApplication] delegate];
    
    switch (indexPath.section) {
        case MST_FILES:
        {
            Project *p = [[[Project alloc] init] loadCurrent];
            ProjectFile *f = [[ProjectFile alloc] init];
            f.num = [Store projectFile:p atOffset:indexPath.row];
            assert([Store loadProjectFile:f]);
            [SwiftCodeAppDelegate editFile:f];
            [f release];
            [p release];
        }   break;
            
        case MST_TASKS:
            break;
            
        case MST_PROJECTS:
        {
            Project *p = [[Project alloc] init];
            p.num = [Store projectNumAtOffset:indexPath.row];
            assert([Store loadProject:p]);            
            [Store setCurrentProject:p];
            d.projectSettingsController.proj = p;
            [p release];
            
            [detailViewController switchTo:d.projectSettingsController];
        }   break;
            
        default: assert(false);
    }
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [detailViewController release];
    [super dealloc];
}


@end

