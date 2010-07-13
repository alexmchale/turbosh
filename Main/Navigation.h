#import <Foundation/Foundation.h>

void switch_to_controller(UIViewController<ContentPaneDelegate> *nextController);
void switch_to_edit_project(Project *project);
void switch_to_edit_current_project();
void switch_to_list();
void adjust_current_controller();
void present_dialog(UIViewController *controller);
