#import "SwiftCodeAppDelegate.h"

#import "RootViewController.h"
#import "DetailViewController.h"

@implementation SwiftCodeAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController;
@synthesize projectSettingsController, fileViewController, taskExecController;
@synthesize synchronizer;

+ (void) switchTo:(UIViewController *)controller
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.detailViewController switchTo:controller];
}

+ (void) editProject:(Project *)project
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.projectSettingsController == nil) {
        ProjectSettingsController *psc =
            [[ProjectSettingsController alloc] initWithNibName:nil bundle:nil];
        delegate.projectSettingsController = psc;
        [psc release];
    }

    delegate.rootViewController.title = project.name;
    delegate.projectSettingsController.proj = project;

    [Store setCurrentProject:project];

    [self switchTo:delegate.projectSettingsController];
}

+ (void) editFile:(ProjectFile *)file
{
    [self editFile:file atRect:CGRectMake(0, 0, 0, 0)];
}

+ (void) editFile:(ProjectFile *)file atRect:(CGRect)startingRect
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.fileViewController == nil) {
        FileViewController *psc =
        [[FileViewController alloc] initWithNibName:nil bundle:nil];
        delegate.fileViewController = psc;
        [psc release];
    }

    if (file != nil) {
        delegate.fileViewController.file = file;
        [Store setCurrentFile:file];
    }

    delegate.fileViewController.startingRect = startingRect;

    [self switchTo:delegate.fileViewController];
}

+ (void) editCurrentFile
{
    ProjectFile *file = [[ProjectFile alloc] init];
    file.num = [Store currentFileNum];
    [Store loadProjectFile:file];
    [self editFile:file];
    [file release];
}

+ (ProjectFile *) currentFile
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    return [delegate.fileViewController file];
}

+ (void) launchTask:(ProjectFile *)f
{
    Project *p = f.project;
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.taskExecController == nil) {
        TaskExecController *psc =
            [[TaskExecController alloc] initWithNibName:@"TaskExecController" bundle:nil];
        delegate.taskExecController = psc;
        [psc release];
    }

    CommandDispatcher *cd = [[CommandDispatcher alloc] initWithProject:p session:NULL command:f.filename];
    delegate.taskExecController.dispatcher = cd;
    [SwiftCodeAppDelegate switchTo:delegate.taskExecController];
    [cd release];
}

+ (void) sync
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.synchronizer synchronize];
}

+ (void) queueCommand:(CommandDispatcher *)dispatcher
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.synchronizer appendCommand:dispatcher];
}

+ (void) reloadList
{
    SwiftCodeAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.rootViewController.tableView reloadData];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    // Initialize the database.
    [Store open];

    // Add the split view controller's view to the window and display.
    [window addSubview:splitViewController.view];
    [window makeKeyAndVisible];

    // Select that last used project and update the DVC to show it.
    Project *currentProject = [[[Project alloc] init] loadCurrent];
    [SwiftCodeAppDelegate editProject:currentProject];
    [currentProject release];

    // Start the file synchronizer.
    synchronizer = [[Synchronizer alloc] init];
    [[NSRunLoop mainRunLoop] addTimer:synchronizer.timer forMode:NSDefaultRunLoopMode];

    return YES;

}

- (void) up123:(NSNotification *)notif
{
    NSNumber *offset = [notif.userInfo valueForKey:@"offset"];
    NSNumber *length = [notif.userInfo valueForKey:@"length"];

    NSLog(@"NOTIFIED %@ %@", offset, length);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Save data if appropriate
    [Store close];
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [splitViewController release];
    [rootViewController release];
    [detailViewController release];
    [projectSettingsController release];
    [fileViewController release];
    [window release];

    [super dealloc];
}

@end

