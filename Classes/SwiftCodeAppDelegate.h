#import <UIKit/UIKit.h>

@class RootViewController;
@class DetailViewController;
@class ProjectSettingsController;
@class Project;

@interface SwiftCodeAppDelegate : NSObject <UIApplicationDelegate>
{
    
    UIWindow *window;
    
    UISplitViewController *splitViewController;
    
    RootViewController *rootViewController;
    DetailViewController *detailViewController;
    
    ProjectSettingsController *projectSettingsController;
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@property (nonatomic, retain) ProjectSettingsController *projectSettingsController;

+ (void) switchTo:(UIViewController *)controller;
+ (void) editProject:(Project *)project;

@end
