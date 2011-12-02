//
//  TextsTableViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Text, TextsTableViewController;

@protocol TextsTableViewDelegate

// Sent after the user selected a text.
- (void)textsTableViewControllerDidSelectText:(TextsTableViewController *)sender;

@end

@interface TextsTableViewController : UITableViewController {
}

// The current text.
@property (nonatomic, retain) Text *currentText;

@property (nonatomic, assign) id <TextsTableViewDelegate> delegate;

@end
