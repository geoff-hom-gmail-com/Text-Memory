//
//  RootViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditTextViewController.h"
#import "FontSizeViewController.h"
#import "RecordingAndPlaybackController.h"
#import "TextsTableViewController.h"

@class Text;

// String for maintaining width of text views. ~1.5 alphabets.
extern NSString *testWidthString;

@interface RootViewController : UIViewController <EditTextViewControllerDelegate, FontSizeViewControllerDelegate, RecordingAndPlaybackControllerDelegate, TextsTableViewDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate> {

@private
    Text *introText_;
}

// Button for adding a text.
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addTextBarButtonItem;

// Toolbar at the bottom of the screen.
@property (nonatomic, retain) IBOutlet UIToolbar *bottomToolbar;

// The current text.
@property (nonatomic, retain) Text *currentText;

// Text view for showing the current text.
@property (nonatomic, retain) IBOutlet UITextView *currentTextTextView;

// Button for editing the current text.
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editTextBarButtonItem;

@property (nonatomic, retain, readonly) Text *introText;

// Button for recording the user's voice and playing it back.
@property (nonatomic, retain) IBOutlet UIBarButtonItem *recordBarButtonItem;

// A segmented control for whether full text or first letters is shown.
@property (nonatomic, retain) IBOutlet UISegmentedControl *textToShowSegmentedControl;

// The title of the current text.
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;

// Toolbar at the top of the screen.
@property (nonatomic, retain) IBOutlet UIToolbar *topToolbar;

// The trash button (for deleting the current text).
@property (nonatomic, retain) IBOutlet UIBarButtonItem *trashBarButtonItem;

// UIActionSheetDelegate method. Since the action sheet was dismissed, clear its reference. Also check if the delete button was tapped.
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;

// Show text according to the segment selected: full text or first letters.
- (IBAction)changeTextModeToShow:(UISegmentedControl *)theSegmentedControl;

// User tapped to add a text. Ask for confirmation.
- (IBAction)confirmAddText:(id)sender;

// User tapped to delete the current text. Ask for confirmation.
- (IBAction)confirmDeleteCurrentText:(id)sender;

// User tapped to edit the current text. Ask for confirmation (or type of editing).
- (IBAction)confirmEditCurrentText:(id)sender;

// EditTextViewControllerDelegate method. Since the text may have changed, update the view.
- (void)editTextViewControllerDidFinishEditing:(EditTextViewController *)sender;

// FontSizeViewControllerDelegate method. Since the font size changed, update the font in the text view.
- (void)fontSizeViewControllerDidChangeFontSize:(FontSizeViewController *)theFontSizeViewController;

// UIGestureRecognizerDelegate method. Allow the gesture recognizer with this class as the delegate to work with others.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

// A double tap was made in a text margin. Toggle first letters or full text.
- (void)handleMarginDoubleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer;

// A single tap was made in a text margin. If showing first letters, then reset the first letters (i.e., hide any full text that was revealed).
- (void)handleMarginSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer;

// A double tap was made in the text view. If it's showing first letters, record that. Check whether to show the full text for the text view's selection.
- (void)handleTextViewDoubleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer;

// UIPopoverControllerDelegate method. Since the popover was dismissed, re-enable the corresponding toolbar.
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;

// RecordingAndPlaybackControllerDelegate method. Since playback started, show that in the button for the popover.
- (void)recordingAndPlaybackControllerDidStartPlaying:(RecordingAndPlaybackController *)recordingAndPlaybackController;

// RecordingAndPlaybackControllerDelegate method. Since recording started, show that in the button for the popover.
- (void)recordingAndPlaybackControllerDidStartRecording:(RecordingAndPlaybackController *)recordingAndPlaybackController;

// RecordingAndPlaybackControllerDelegate method. Since playback stopped, show that in the button for the popover.
- (void)recordingAndPlaybackControllerDidStopPlaying:(RecordingAndPlaybackController *)recordingAndPlaybackController;

// RecordingAndPlaybackControllerDelegate method. Since recording stopped, show that in the button for the popover.
- (void)recordingAndPlaybackControllerDidStopRecording:(RecordingAndPlaybackController *)recordingAndPlaybackController;

// Show/hide popover for changing the font size.
- (IBAction)showFontSizePopover:(id)sender;

// Show/hide popover for recording/playback.
- (IBAction)showRecordingPopover:(id)sender;

// Show/hide popover for selecting a text.
- (IBAction)showTextsPopover:(id)sender;

// TextsTableViewDelegate method. Since the user selected a text, dismiss the popover and show the text.
- (void)textsTableViewControllerDidSelectText:(TextsTableViewController *)sender;

// UITextViewDelegate method. If in first-letter mode, show the selection's full text. (Exceptions: ?)
- (void)textViewDidChangeSelection:(UITextView *)theTextView;

@end
