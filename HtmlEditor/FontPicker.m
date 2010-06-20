#import "FontPicker.h"



static NSInteger fontSizes[] = { 12, 14, 16, 18, 20 };

static NSString *fontSizeNames[] = {
    @"X-Small", @"Small", @"Medium", @"Large", @"X-Large"
};

static const int FONT_SIZE_COUNT = 5;



@implementation FontPickerController

@synthesize delegate = _delegate;

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(clearsSelectionOnViewWillAppear)]) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(150.0, 225.0);
    }

    self.tableView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return FONT_SIZE_COUNT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    NSString *fontSizeName = fontSizeNames[indexPath.row % FONT_SIZE_COUNT];
    cell.textLabel.text = fontSizeName;

    if ([Store fontSize] == fontSizes[indexPath.row % FONT_SIZE_COUNT])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;

    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.delegate != nil) {
        NSInteger size = fontSizes[indexPath.row % FONT_SIZE_COUNT];

        [self.delegate fontChanged:size];
    }
}

#pragma mark Memory management

- (void)viewDidUnload
{
    self.delegate = nil;
}

- (void)dealloc
{
    self.delegate = nil;

    [super dealloc];
}

@end
