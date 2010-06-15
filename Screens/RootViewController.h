//
//  RootViewController.h
//  Turbosh
//
//  Created by Alex McHale on 3/24/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface RootViewController : UITableViewController {
    DetailViewController *detailViewController;

    Project *project;
    NSArray *files;
    NSArray *tasks;
}

@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSArray *files;
@property (nonatomic, retain) NSArray *tasks;

- (void) reload;

@end
