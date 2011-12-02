//
//  FontSizeViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Text, FontSizeViewController;

@protocol FontSizeViewControllerDelegate

// Sent after the user chose a smaller or larger font size.
- (void)fontSizeViewControllerDidChangeFontSize:(FontSizeViewController *)theFontSizeViewController;

@end

@interface FontSizeViewController : UIViewController {

}

// The current font size to show.
@property (nonatomic) CGFloat currentFontSize;

// The button for decreasing font size.
@property (nonatomic, retain) IBOutlet UIButton *decreaseFontSizeButton;

@property (nonatomic, assign) id <FontSizeViewControllerDelegate> delegate;

// The button for increasing font size.
@property (nonatomic, retain) IBOutlet UIButton *increaseFontSizeButton;

// Decrease current font size by 2.
- (IBAction)decreaseFontSize:(id)sender;

// Increase current font size by 2.
- (IBAction)increaseFontSize:(id)sender;

@end
