#import "TurboshAppDelegate.h"

#import "RootViewController.h"
#import "DetailViewController.h"

@implementation TurboshAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController;
@synthesize projectSettingsController, fileViewController, taskExecController;
@synthesize synchronizer;

+ (void) switchTo:(UIViewController *)controller
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    [delegate.detailViewController switchTo:controller];
}

+ (void) setLabelText:(NSString *)text
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.detailViewController.label.text = text;
}

+ (void) setMenuText:(NSString *)text
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.rootViewController.title = text;
}

+ (void) editProject:(Project *)project
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.projectSettingsController == nil) {
        ProjectSettingsController *psc;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            psc = [[ProjectSettingsController alloc] initWithNibName:@"ProjectSettingsController-iPad" bundle:nil];
        else
            psc = [[ProjectSettingsController alloc] initWithNibName:@"ProjectSettingsController-iPhone" bundle:nil];

        delegate.projectSettingsController = psc;
        [psc release];
    }

    delegate.rootViewController.title = project.name;
    [delegate.projectSettingsController setProject:project];

    [Store setCurrentProject:project];

    [self switchTo:delegate.projectSettingsController];
}

+ (void) editFile:(ProjectFile *)file
{
    [self editFile:file atRect:CGRectMake(0, 0, 0, 0)];
}

+ (void) editFile:(ProjectFile *)file atRect:(CGRect)startingRect
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.fileViewController == nil) {
        FileViewController *psc =
        [[FileViewController alloc] initWithNibName:nil bundle:nil];
        delegate.fileViewController = psc;
        [psc release];
    }

    if (file.num) {
        delegate.fileViewController.file = file;
        delegate.fileViewController.startingRect = startingRect;
    }

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
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    return [delegate.fileViewController file];
}

+ (void) launchTask:(ProjectFile *)f
{
    Project *p = f.project;
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.taskExecController == nil) {
        TaskExecController *psc =
            [[TaskExecController alloc] initWithNibName:@"TaskExecController" bundle:nil];
        delegate.taskExecController = psc;
        [psc release];
    }

    NSString *commandArgs = [f content];
    if (!commandArgs) commandArgs = @"";
    NSString *commandString = [NSString stringWithFormat:@"%@ %@", f.filename, commandArgs];
    CommandDispatcher *cd = [[CommandDispatcher alloc] initWithProject:p session:NULL command:commandString];
    delegate.taskExecController.dispatcher = cd;
    [TurboshAppDelegate switchTo:delegate.taskExecController];
    [cd release];
}

+ (Synchronizer *) synchronizer
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    return delegate.synchronizer;
}

+ (void) sync
{
    [[self synchronizer] synchronize];
}

+ (void) sync:(NSNumber *)projectNumber
{
    [[self synchronizer] synchronize:projectNumber];
}

+ (void) queueCommand:(CommandDispatcher *)dispatcher
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.synchronizer appendCommand:dispatcher];
}

+ (void) reloadList
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.rootViewController reload];
}

+ (void) spin:(bool)spinning
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    UIActivityIndicatorView *spinner = delegate.detailViewController.spinner;

    if (spinning)
        [spinner startAnimating];
    else
        [spinner stopAnimating];
}

+ (void) clearToolbar
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.detailViewController clearToolbar];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize the database.
    [Store open];

    // Initialize the public/private key pair.
    [[[KeyPair alloc] init] release];

    if (splitViewController) {
        [window addSubview:splitViewController.view];
        [window makeKeyAndVisible];
    } else if (detailViewController) {
        [window addSubview:detailViewController.view];
        [window makeKeyAndVisible];
    } else {
        assert(false);
    }

    // Select that last used project and update the DVC to show it.
    Project *currentProject = [[[Project alloc] init] loadCurrent];
    [TurboshAppDelegate editProject:currentProject];
    [currentProject release];

    // Start the file synchronizer.
    synchronizer = [[Synchronizer alloc] init];
    [[NSRunLoop mainRunLoop] addTimer:synchronizer.timer forMode:NSDefaultRunLoopMode];

    return YES;
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

