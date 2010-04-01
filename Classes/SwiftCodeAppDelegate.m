#import "SwiftCodeAppDelegate.h"

#import "RootViewController.h"
#import "DetailViewController.h"

@implementation SwiftCodeAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController, projectSettingsController;

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
    
    delegate.projectSettingsController.proj = project;
    [self switchTo:delegate.projectSettingsController];
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
    [SwiftCodeAppDelegate editProject:[Store currentProject]];

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
    [window release];
    [super dealloc];
}

@end

