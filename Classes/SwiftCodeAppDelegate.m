//
//  SwiftCodeAppDelegate.m
//  SwiftCode
//
//  Created by Alex McHale on 3/24/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "SwiftCodeAppDelegate.h"


#import "RootViewController.h"
#import "DetailViewController.h"

#import <sqlite3.h>

@implementation SwiftCodeAppDelegate

@synthesize window, splitViewController, rootViewController, detailViewController, projectSettingsController;


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
    self.projectSettingsController = [[[ProjectSettingsController alloc] initWithNibName:nil bundle:nil] autorelease];
    projectSettingsController.proj = [Store currentProject];
    [detailViewController switchTo:projectSettingsController];
    
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

