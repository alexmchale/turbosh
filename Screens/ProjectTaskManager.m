#import "ProjectTaskManager.h"

@implementation ProjectTaskManager

@synthesize project;
@synthesize files;
@synthesize cmdFields;
@synthesize argFields;

#pragma mark Actions

- (void) saveAction
{
    for (int i = 0; i < files.count; ++i) {
        ProjectFile *file = [files objectAtIndex:i];

        TextFieldCell *cmdCel = [cmdFields objectAtIndex:i];
        TextFieldCell *argCel = [argFields objectAtIndex:i];

        NSString *cmd = cmdCel.text.text;
        NSData *args = [argCel.text.text dataWithAutoEncoding];
        if (!args) args = [NSData data];

        if ([cmd hasContent]) {
            file.filename = cmd;
            [Store storeProjectFile:file];
            [Store storeLocal:file content:args];
        } else {
            [Store deleteProjectFile:file];
        }
    }

    [TurboshAppDelegate reloadList];
    [TurboshAppDelegate editProject:project];
}

- (void) cancelAction
{
    [TurboshAppDelegate editProject:project];
}

#pragma mark View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    self.project = [Project current];
    self.files = [project files:FU_TASK];

    TextFieldCell *cell;

    NSMutableArray *newCmdFields = [[NSMutableArray alloc] init];
    NSMutableArray *newArgFields = [[NSMutableArray alloc] init];

    for (ProjectFile *f in files) {
        cell = [TextFieldCell cellForTableView:self.tableView labeled:@"Command"];
        cell.text.text = f.filename;
        [newCmdFields addObject:cell];

        cell = [TextFieldCell cellForTableView:self.tableView labeled:@"Arguments"];
        cell.text.text = [f content];
        [newArgFields addObject:cell];
    }

    self.cmdFields = newCmdFields;
    self.argFields = newArgFields;

    [newCmdFields release];
    [newArgFields release];

    [TurboshAppDelegate setLabelText:@"Task Configuration"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return files ? [files count] : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return PTM_ROW_COUNT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    switch (indexPath.row) {
        case PTM_COMMAND:
            cell = [cmdFields objectAtIndex:indexPath.section];

            break;

        case PTM_PARAMETERS:
            cell = [argFields objectAtIndex:indexPath.section];

            break;
    }

    assert(cell);

    return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Memory management

- (void)viewDidUnload
{
    self.project = nil;
    self.files = nil;
    self.cmdFields = nil;
    self.argFields = nil;
}

- (void)dealloc
{
    self.project = nil;
    self.files = nil;
    self.cmdFields = nil;
    self.argFields = nil;

    [super dealloc];
}

#pragma mark Toolbar Management

- (void) viewSwitcher:(DetailViewController *)switcher configureToolbar:(UIToolbar *)toolbar {
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
             target:self
             action:@selector(cancelAction)];

    UIBarButtonItem *spacer =
        [[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
             target:nil
             action:nil];

    UIBarButtonItem *saveButton =
        [[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemSave
             target:self
             action:@selector(saveAction)];

    [toolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, saveButton, nil]];

    [cancelButton release];
    [spacer release];
    [saveButton release];
}

@end

