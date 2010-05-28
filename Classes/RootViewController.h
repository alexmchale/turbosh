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
    NSInteger currentProjectNum;
}

@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

- (void) reload;

@end
