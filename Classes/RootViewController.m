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

    self.view.backgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
}

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
        case MST_FILES:     return [Store fileCountForCurrentProject] ? @"Files" : @"";
        case MST_TASKS:     return [Store taskCountForCurrentProject] ? @"Tasks" : @"";
        case MST_PROJECTS:  return @"Projects";
        default:            return @"";
    }
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MST_FILES:     return [Store fileCountForCurrentProject];
        case MST_TASKS:     return [Store taskCountForCurrentProject];
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
            [file loadByNumber:[Store projectFileNumber:project atOffset:indexPath.row]];
            cell.textLabel.text = [file condensedPath];
            break;

        case MST_TASKS:
            [project loadCurrent];
            file.num = [Store projectTaskNumber:project atOffset:indexPath.row];
            file.project = project;
            assert([Store loadProjectTask:file]);
            cell.textLabel.text = [file condensedPath];
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
            f.num = [Store projectFileNumber:p atOffset:indexPath.row];
            f.project = p;
            assert([Store loadProjectFile:f]);
            [SwiftCodeAppDelegate editFile:f];
            [f release];
            [p release];
        }   break;

        case MST_TASKS:
        {
            Project *p = [[[Project alloc] init] loadCurrent];
            ProjectFile *f = [[ProjectFile alloc] init];
            f.num = [Store projectTaskNumber:p atOffset:indexPath.row];
            f.project = p;
            assert([Store loadProjectTask:f]);
            [SwiftCodeAppDelegate launchTask:f];
            [f release];
            [p release];
        }   break;

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

