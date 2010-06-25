#import <UIKit/UIKit.h>

@protocol FontPickerDelegate
- (void) configurationChanged;
@end

@interface FontPickerController : UITableViewController <ContentPaneDelegate>
{
    id<FontPickerDelegate> _delegate;
}

@property (nonatomic, retain) id<FontPickerDelegate> delegate;

@end
