#import "TurboshAppDelegate.h"

#import "RootViewController.h"
#import "DetailViewController.h"

@implementation TurboshAppDelegate

@synthesize window, splitViewController, menuController, rootViewController, detailViewController;
@synthesize projectSettingsController, fileViewController, taskExecController;
@synthesize masterController;
@synthesize synchronizer;

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

+ (void) editFile:(ProjectFile *)file
{
    [self editFile:file atRect:CGRectMake(0, 0, 0, 0)];
}

+ (void) editFile:(ProjectFile *)file atRect:(CGRect)startingRect
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    if (delegate.fileViewController == nil) {
        NSString *nib = IS_IPAD ? @"FileViewController-iPad" : @"FileViewController-iPhone";
        FileViewController *psc = [[FileViewController alloc] initWithNibName:nib bundle:nil];
        delegate.fileViewController = psc;
        [psc release];
    }

    if (file.num) {
        delegate.fileViewController.file = file;
        delegate.fileViewController.startingRect = startingRect;
    }

    switch_to_controller(delegate.fileViewController);
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
        NSString *nibName = IS_IPAD ? @"TaskExecController-iPad" : @"TaskExecController-iPhone";
        TaskExecController *psc = [[TaskExecController alloc] initWithNibName:nibName bundle:nil];
        delegate.taskExecController = psc;
        [psc release];
    }

    NSString *commandArgs = [f content];
    if (!commandArgs) commandArgs = @"";
    NSString *commandString = [NSString stringWithFormat:@"%@ %@", f.filename, commandArgs];
    CommandDispatcher *cd = [[CommandDispatcher alloc] initWithProject:p session:NULL command:commandString];
    delegate.taskExecController.dispatcher = cd;
    switch_to_controller(delegate.taskExecController);
    [cd release];
}

+ (Synchronizer *) synchronizer
{
    TurboshAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    return delegate.synchronizer;
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

- (void) switchToList
{
    if (IS_IPAD) {
        if (!self.detailViewController.popoverController) {
            self.detailViewController.popoverController =
                [[[UIPopoverController alloc]
                  initWithContentViewController:menuController]
                 autorelease];
        }

        [self.detailViewController.popoverController
             presentPopoverFromBarButtonItem:detailViewController.projectButton
             permittedArrowDirections:UIPopoverArrowDirectionAny
             animated:YES];
    } else {
        switch_to_list();
    }
}

#pragma mark -
#pragma mark Application lifecycle

- (void) buildWindow
{
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    rootViewController = [[RootViewController alloc] init];
    detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailView" bundle:nil];

    [self.detailViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];

    if (IS_IPAD) {
        self.menuController =
            [[[UINavigationController alloc]
              initWithRootViewController:rootViewController]
             autorelease];
    }

    if (IS_SPLIT) {
        UISplitViewController *svc = [[UISplitViewController alloc] init];
        splitViewController = svc;

        svc.delegate = detailViewController;

        NSMutableArray *splitControllers = [NSMutableArray arrayWithObjects:menuController, detailViewController, nil];
        [splitViewController setViewControllers:splitControllers];

        self.masterController = splitViewController;
    } else {
        CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
        self.detailViewController.view.frame = screenFrame;

        [detailViewController createProjectButton];
        self.masterController = detailViewController;
    }

    [window addSubview:masterController.view];
    [window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize the database.
    [Store open];

    // Initialize the public/private key pair.
    [[[KeyPair alloc] init] release];

    // Insert the main view.
    [self buildWindow];

    // Redirect the logging to a file if we're not in DEBUG mode.
    const NSString *nsLogPath = user_file_path(@"console.log");
    const char *logPath = [nsLogPath cStringUsingEncoding:NSASCIIStringEncoding];
#ifdef NDEBUG
    freopen(logPath, "w", stderr);
#else
    FILE *logFile = fopen(logPath, "w");
    fprintf(logFile, "No log file is available in debug mode.");
    fclose(logFile);
#endif

    // Log the current startup time.
    NSLog(@"Turbosh App Startup at %@", [NSDate date]);

    // Select that last used project and update the DVC to show it.
    Project *currentProject = [Project current];

    if (IS_IPAD)
        switch_to_edit_project(currentProject);
    else
        switch_to_list();

    // Start the file synchronizer.
    synchronizer = [[Synchronizer alloc] init];
    [[NSRunLoop mainRunLoop] addTimer:synchronizer.timer forMode:NSDefaultRunLoopMode];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    synchronizer_stop();
    [Store close];

    NSLog(@"Turbosh has terminated.");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"Turbosh is being put into the background.");

    synchronizer_stop();

    if([CURRENT_DEVICE respondsToSelector:@selector(isMultitaskingSupported)]) {
        UIBackgroundTaskIdentifier bgTask = 0;

        bgTask =
            [application beginBackgroundTaskWithExpirationHandler: ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [application endBackgroundTask:bgTask];
                });
            }];

        dispatch_async(dispatch_get_main_queue(), ^{
            synchronizer_run();
            [application endBackgroundTask:bgTask];
        });
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"Turbosh is waking up from background.");

    [TurboshAppDelegate spin:false];
    synchronizer_start();
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

