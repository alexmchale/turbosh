#import "FontPicker.h"

@implementation FontPickerController

@synthesize delegate = _delegate;

#pragma mark Constants

static NSInteger fontSizes[] = { 12, 14, 16, 18, 20 };

static NSString *fontSizeNames[] = {
    @"X-Small", @"Small", @"Medium", @"Large", @"X-Large"
};

static const int FONT_SIZE_COUNT = 5;

static NSString *syntaxTypes[] = {
    @"c", @"cpp", @"csharp", @"css", @"html",
    @"java", @"javascript", @"latex", @"perl", @"php",
    @"python", @"ruby", @"scala", @"sql", @"tcl",
    @"xml"
};

static const int SYNTAX_COUNT = 16;

typedef enum {
    SECTION_FONT_SIZE,
    SECTION_THEME,
    SECTION_SPLIT,
    SECTION_SYNTAX,
    SECTION_COUNT
} Sections;

#pragma mark Actions

- (void) saveAction
{
    [TurboshAppDelegate editCurrentFile];
}

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];

    if (IS_IPHONE) [TurboshAppDelegate setLabelText:@"Configuration"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(clearsSelectionOnViewWillAppear)]) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(200.0, 350.0);
    }

    self.tableView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];
}

#pragma mark Table view data source

- (UIView *) tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section
{
    // Make sure this section has a header.
    NSString *text = [self tableView:aTableView titleForHeaderInSection:section];
    if (!text || [text length] == 0) return nil;

    // Build the header view.
    CGRect frame = CGRectMake(0, 0, aTableView.bounds.size.width, 30);
    UIView *headerView = [[[UIView alloc] initWithFrame:frame] autorelease];

    // Configure the view.
    headerView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0];

    // Add the label.
    CGRect labelFrame = CGRectMake(10, 3, frame.size.width - 20, 18);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.text = text;
    label.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textAlignment = UITextAlignmentRight;
    [headerView addSubview:label];
    [label release];

    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_FONT_SIZE: return FONT_SIZE_COUNT;
        case SECTION_THEME:     return [[Theme all] count];
        case SECTION_SPLIT:     return IS_IPAD ? 1 : 0;
        case SECTION_SYNTAX:    return SYNTAX_COUNT;
        default: assert(false);
    }

    return 0;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SECTION_FONT_SIZE: return @"Font Size";
        case SECTION_THEME:     return @"Color Scheme";
        case SECTION_SPLIT:     return IS_IPAD ? @"App Layout" : nil;
        case SECTION_SYNTAX:    return @"File Syntax";
        default: assert(false);
    }

    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    switch (indexPath.section) {
        case SECTION_FONT_SIZE:
        {
            NSString *fontSizeName = fontSizeNames[indexPath.row % FONT_SIZE_COUNT];
            cell.textLabel.text = fontSizeName;

            if ([Store fontSize] == fontSizes[indexPath.row % FONT_SIZE_COUNT])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;

            break;
        }

        case SECTION_THEME:
        {
            Theme *theme = [[Theme all] objectAtIndex:indexPath.row];
            cell.textLabel.text = theme.turboshName;

            if ([theme.shjsName isEqual:[Store theme].shjsName])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;

            break;
        }

        case SECTION_SPLIT:
        {
            cell.textLabel.text = @"Split View";
            cell.accessoryType = CHECKMARK([Store isSplit]);

            break;
        }

        case SECTION_SYNTAX:
        {
            NSString *syntax = syntaxTypes[indexPath.row % SYNTAX_COUNT];
            ProjectFile *file = [ProjectFile current];
            cell.textLabel.text = syntax;

            if ([syntax isEqualToString:file.contentType])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;

            break;
        }

        default: assert(false);
    }

    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    // Remove all checkmarks from the previously selected item.
    for (int i = 0; i < [tableView numberOfRowsInSection:indexPath.section]; ++i) {
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:lastIndexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Select the newly selected item.
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    switch (indexPath.section) {
        case SECTION_FONT_SIZE:
        {
            NSInteger size = fontSizes[indexPath.row % FONT_SIZE_COUNT];
            [Store setFontSize:size];

            break;
        }

        case SECTION_THEME:
        {
            [Store setTheme:[[Theme all] objectAtIndex:indexPath.row]];

            break;
        }

        case SECTION_SPLIT:
        {
            bool isNowSet = ![Store isSplit];
            [Store setSplit:isNowSet];

            show_alert(@"Split Changed", @"You must restart Turbosh for this change to take effect.");
            break;
        }

        case SECTION_SYNTAX:
        {
            ProjectFile *file = [ProjectFile current];
            file.contentType = syntaxTypes[indexPath.row % SYNTAX_COUNT];

            break;
        }

        default: assert(false);
    }

    if (self.delegate != nil) [self.delegate configurationChanged];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    UIBarButtonItem *spacer =
        [[[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
          target:nil
          action:nil] autorelease];

    UIBarButtonItem *saveButton =
        [[[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemSave
          target:self
          action:@selector(saveAction)] autorelease];

    [toolbar setItems:[NSArray arrayWithObjects:spacer, saveButton, nil]];
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
