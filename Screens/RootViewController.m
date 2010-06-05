#import "RootViewController.h"
#import "DetailViewController.h"

@implementation RootViewController

@synthesize detailViewController;

#pragma mark Management

- (void) reload
{
    [self.tableView reloadData];

    currentProjectNum = [[Store currentProjectNum] intValue];
}

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    self.tableView.tableHeaderView.backgroundColor = [UIColor redColor];
}

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

#pragma mark Table Header

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case MST_FILES:     return [Store fileCountForCurrentProject:FU_FILE] ? @"Files" : @"";
        case MST_TASKS:     return [Store fileCountForCurrentProject:FU_TASK] ? @"Tasks" : @"";
        case MST_PROJECTS:  return @"Projects";
        default:            return @"";
    }
}

- (UIView *) tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
    // Make sure this section has a header.
    NSString *text = [self tableView:aTableView titleForHeaderInSection:section];
    if (!text || [text length] == 0) return nil;

    // Build the header view.
    CGRect frame = CGRectMake(0, 0, aTableView.bounds.size.width, 30);
    UIView *headerView = [[[UIView alloc] initWithFrame:frame] autorelease];

    // Configure the view.
    headerView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];

    // Add the label.
    CGRect labelFrame = CGRectMake(10, 3, frame.size.width - 20, 18);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text = text;
    label.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textAlignment = UITextAlignmentRight;
    [headerView addSubview:label];
    [label release];

    return headerView;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MST_FILES:     return [Store fileCountForCurrentProject:FU_FILE];
        case MST_TASKS:     return [Store fileCountForCurrentProject:FU_TASK];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.section) {
        case MST_FILES:
            [project loadCurrent];
            [file loadByNumber:[Store projectFileNumber:project atOffset:indexPath.row ofUsage:FU_FILE]];
            cell.textLabel.text = [file condensedPath];
            break;

        case MST_TASKS:
            [project loadCurrent];
            file.num = [Store projectFileNumber:project atOffset:indexPath.row ofUsage:FU_TASK];
            file.project = project;
            file.usage = FU_TASK;
            [Store loadProjectFile:file];
            cell.textLabel.text = [file condensedPath];
            break;

        case MST_PROJECTS:
            [project loadByOffset:indexPath.row];
            cell.textLabel.text = project.name;
//            if (project.num && [project.num intValue] == currentProjectNum)
//                cell.accessoryType = UITableViewCellAccessoryCheckmark;
//            else
//                cell.accessoryType = UITableViewCellAccessoryNone;
            break;
    }

    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    [file release];
    [project release];

    return cell;

}

#pragma mark -
#pragma mark Table view delegate

- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MST_FILES:
        {
            Project *p = [[[Project alloc] init] loadCurrent];
            ProjectFile *f = [[ProjectFile alloc] init];
            f.num = [Store projectFileNumber:p atOffset:indexPath.row ofUsage:FU_FILE];
            f.project = p;
            [Store loadProjectFile:f];

            if (f.remoteMd5)
                [TurboshAppDelegate editFile:f];
            else
                show_alert(@"File Not Ready", @"That file has not yet been downloaded from the server.");

            [f release];
            [p release];
        }   break;

        case MST_TASKS:
        {
            Project *p = [[[Project alloc] init] loadCurrent];
            ProjectFile *f = [[ProjectFile alloc] init];
            f.num = [Store projectFileNumber:p atOffset:indexPath.row ofUsage:FU_FILE];
            f.project = p;
            f.usage = FU_TASK;
            [Store loadProjectFile:f];
            [TurboshAppDelegate launchTask:f];
            [f release];
            [p release];
        }   break;

        case MST_PROJECTS:
        {
            Project *p = [[Project alloc] init];
            p.num = [Store projectNumAtOffset:indexPath.row];
            [Store loadProject:p];
            [TurboshAppDelegate editProject:p];
            [p release];
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

