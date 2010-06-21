#import "UITableViewUtil.h"

@implementation UITableView (uitableview_monkey)

- (UITableViewCell *) cellForId:(NSString *)myId
                      withStyle:(UITableViewCellStyle)myStyle
{
    UITableViewCell *cell = [self dequeueReusableCellWithIdentifier:myId];

    if (cell == nil) {
        cell =
            [[[UITableViewCell alloc]
                initWithStyle:myStyle
              reuseIdentifier:myId] autorelease];
    }

    return cell;
}

@end
