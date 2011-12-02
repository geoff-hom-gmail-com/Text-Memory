//
//  EditTextViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditTextViewController, Text;

@protocol EditTextViewControllerDelegate

// Sent after the user finished editing the text.
- (void)editTextViewControllerDidFinishEditing:(EditTextViewController *)sender;

@end

@interface EditTextViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate> {
}

// Amount to offset the text by when initially displaying.
@property (nonatomic) CGPoint contentOffset;

// The current text.
@property (nonatomic, retain) Text *currentText;

// Text view for showing the current text.
@property (nonatomic, retain) IBOutlet UITextView *currentTextTextView;

@property (nonatomic, assign) id <EditTextViewControllerDelegate> delegate;

// The title of the current text.
@property (nonatomic, retain) IBOutlet UIBarButtonItem *titleBarButtonItem;

// UIAlertViewDelegate method. If the "Done" button was clicked, then save the new title. (Would use alertView:clickedButtonAtIndex:, but we also need to activate the "Done" button programmatically. The only way to do that is [alertView dismissWithClickedButtonIndex:animated], which skips alertView:clickedButtonAtIndex:.) 
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex;

// Cancel any changes and go back to the main view.
- (IBAction)cancelEditing:(id)sender;

// The designated initializer.
- (id)initWithText:(Text *)theText contentOffset:(CGPoint)theContentOffset font:(UIFont *)theFont;

// Show an alert view for renaming the text's title.
- (IBAction)renameTitle:(id)sender;

// Save changes to current text and go back to the main view.
- (IBAction)saveEditing:(id)sender;

// UITextFieldDelegate method. Since the "Done" key was tapped, mimic the "Done" key in the alert view.
- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end
