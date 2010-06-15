#import "RootViewController.h"
#import "DetailViewController.h"

@implementation RootViewController

@synthesize detailViewController;
@synthesize projects;
@synthesize files;
@synthesize tasks;

#pragma mark Management

- (void) reload
{
    [self.tableView reloadData];

    Project *currentProject = [Project current];
    currentProjectNum = [currentProject.num intValue];

    self.projects = [Store projects];
    self.files = [Store files:currentProject ofUsage:FU_FILE];
    self.tasks = [Store files:currentProject ofUsage:FU_TASK];
}

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    self.tableView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];

    [self reload];
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
        case MST_FILES:     return [files count] ? @"Files" : @"";
        case MST_TASKS:     return [tasks count] ? @"Tasks" : @"";
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
        case MST_FILES:     return [files count];
        case MST_TASKS:     return [tasks count];
        case MST_PROJECTS:  return [projects count];
        default:            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"MenuCellIdentifier";

    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.section) {
        case MST_FILES:
            if (indexPath.row < [files count]) {
                ProjectFile *file = [files objectAtIndex:indexPath.row];
                cell.textLabel.text = [file condensedPath];
            }
            break;

        case MST_TASKS:
            if (indexPath.row < [tasks count]) {
                ProjectFile *file = [tasks objectAtIndex:indexPath.row];
                cell.textLabel.text = [file condensedPath];
            }
            break;

        case MST_PROJECTS:
            if (indexPath.row < [projects count]) {
                Project *project = [projects objectAtIndex:indexPath.row];

                cell.textLabel.text = project.name;
                if (project.num && [project.num intValue] == currentProjectNum)
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                else
                    cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
    }

    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    return cell;

}

#pragma mark Table view delegate

- (void) tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MST_FILES:
            if (indexPath.row < [files count]) {
                ProjectFile *file = [files objectAtIndex:indexPath.row];
                [Store loadProjectFile:file];

                if (file.remoteMd5)
                    [TurboshAppDelegate editFile:file];
                else
                    show_alert(@"File Not Ready", @"That file has not yet been downloaded from the server.");
            }
            break;

        case MST_TASKS:
            if (indexPath.row < [tasks count]) {
                ProjectFile *file = [tasks objectAtIndex:indexPath.row];
                [TurboshAppDelegate launchTask:file];
            }
            break;

        case MST_PROJECTS:
            if (indexPath.row < [projects count]) {
                Project *project = [projects objectAtIndex:indexPath.row];
                [TurboshAppDelegate editProject:project];
            }
            break;

        default: assert(false);
    }

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Memory management

- (void)viewDidUnload
{
    self.detailViewController = nil;
    self.projects = nil;
    self.files = nil;
    self.tasks = nil;
}

- (void)dealloc
{
    [detailViewController release];
    [projects release];
    [files release];
    [tasks release];

    [super dealloc];
}

@end
