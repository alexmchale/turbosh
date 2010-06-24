#import <UIKit/UIKit.h>

@protocol FontPickerDelegate
- (void) fontChanged:(NSInteger)fontSize;
@end

@interface FontPickerController : UITableViewController <ContentPaneDelegate>
{
    id<FontPickerDelegate> _delegate;
}

@property (nonatomic, retain) id<FontPickerDelegate> delegate;

@end
