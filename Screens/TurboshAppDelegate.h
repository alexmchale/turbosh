#import <UIKit/UIKit.h>

@class RootViewController;
@class DetailViewController;
@class ProjectSettingsController;
@class FileViewController;
@class Project;
@class ProjectFile;
@class Synchronizer;
@class CommandDispatcher;
@class TaskExecController;

@interface TurboshAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;

    id splitViewController;
    RootViewController *rootViewController;
    DetailViewController *detailViewController;

    ProjectSettingsController *projectSettingsController;
    FileViewController *fileViewController;
    TaskExecController *taskExecController;

    Synchronizer *synchronizer;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet id splitViewController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@property (nonatomic, retain) ProjectSettingsController *projectSettingsController;
@property (nonatomic, retain) FileViewController *fileViewController;
@property (nonatomic, retain) TaskExecController *taskExecController;

@property (readonly) Synchronizer *synchronizer;

+ (void) setMenuText:(NSString *)text;
+ (void) setLabelText:(NSString *)text;
+ (void) switchTo:(UIViewController *)controller;
+ (void) editProject:(Project *)project;
+ (void) editFile:(ProjectFile *)file;
+ (void) editFile:(ProjectFile *)file atRect:(CGRect)startingRect;
+ (void) editCurrentFile;
+ (void) launchTask:(ProjectFile *)f;
+ (Synchronizer *) synchronizer;
+ (void) sync;
+ (void) sync:(NSNumber *)projectNumber;
+ (void) queueCommand:(CommandDispatcher *)dispatcher;
+ (void) reloadList;
+ (void) spin:(bool)spinning;
+ (void) clearToolbar;

@end
