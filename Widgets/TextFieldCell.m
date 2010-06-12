#import "TextFieldCell.h"

@implementation TextFieldCell

@synthesize text;

#pragma mark Action Handlers

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected) [text becomeFirstResponder];
}

#pragma mark Memory Management

static NSString *CellIdentifier = @"TextFieldCell";

- (id) initWithTableView:(UITableView *)tableView named:(NSString *)name
{
    [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }

    CGRect tableFrame = tableView.frame;
    int yOffset = 10;
    int height = self.frame.size.height - (2 * yOffset);

    UILabel *label = [[UILabel alloc] init];
    label.text = name;
    label.frame = CGRectMake(10, yOffset, 90, height);
    label.font = [UIFont boldSystemFontOfSize:14.0];
    label.textAlignment = UITextAlignmentRight;
    label.backgroundColor = [UIColor clearColor];

    text = [[UITextField alloc] init];
    text.textColor = [UIColor colorWithRed:0.243 green:0.306 blue:0.435 alpha:1.0];
    text.autocorrectionType = UITextAutocorrectionTypeNo;
    text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    text.clearButtonMode = UITextFieldViewModeWhileEditing;

    if (name == nil)
        text.frame = CGRectMake(10, yOffset, tableFrame.size.width - 150, height);
    else
        text.frame = CGRectMake(110, yOffset, tableFrame.size.width - 250, height);

    if (name != nil) [self.contentView addSubview:label];
    [self.contentView addSubview:text];

    [label release];

    return self;
}

- (void) dealloc
{
    [text release];
    [super dealloc];
}

+ (id) cellForTableView:(UITableView *)tableView
{
    return [self cellForTableView:tableView labeled:nil];
}

+ (id) cellForTableView:(UITableView *)tableView labeled:(NSString *)name
{
    id cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[TextFieldCell alloc] initWithTableView:tableView named:name] autorelease];
    }

    return cell;
}

@end
