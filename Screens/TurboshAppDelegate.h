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
}

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) UISplitViewController *splitViewController;
@property (nonatomic, retain) UINavigationController *menuController;
@property (nonatomic, retain) RootViewController *rootViewController;
@property (nonatomic, retain) DetailViewController *detailViewController;

@property (nonatomic, retain) ProjectSettingsController *projectSettingsController;
@property (nonatomic, retain) FileViewController *fileViewController;
@property (nonatomic, retain) TaskExecController *taskExecController;

@property (nonatomic, retain) UIViewController *masterController;
@property (readonly) Synchronizer *synchronizer;

+ (void) setMenuText:(NSString *)text;
+ (void) setLabelText:(NSString *)text;
+ (void) editFile:(ProjectFile *)file;
+ (void) editFile:(ProjectFile *)file atRect:(CGRect)startingRect;
+ (void) editCurrentFile;
+ (void) launchTask:(ProjectFile *)f;
+ (Synchronizer *) synchronizer;
+ (void) sync:(NSNumber *)projectNumber;
+ (void) queueCommand:(CommandDispatcher *)dispatcher;
+ (void) reloadList;
+ (void) spin:(bool)spinning;
+ (void) clearToolbar;

@end
