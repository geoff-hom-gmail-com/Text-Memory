//
//  RootViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultData.h"
#import "EditTextViewController.h"
#import "FontSizeViewController.h"
#import "NSString+Words.h"
#import "OverlayView.h"
#import "RecordingAndPlaybackController.h"
#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Text.h"
#import "TextMemoryAppDelegate.h"
#import "TextsTableViewController.h"

// Set to YES to show UI for launch image. Can capture in simulator: control key -> Edit menu -> Copy Screen -> in GraphicConverter or Preview, File -> New from clipboard.
BOOL createLaunchImages = NO;

// Title for action-sheet button for adding a new text.
NSString *addTextTitleString = @"Add a New Text";

// Characters, except comma, that could be at the end of a clause. (Commas are handled separately because they don't always signal the end of a clause. Periods could also be handled separately because of web addresses and ellipses.)
NSString *clauseEndsExceptCommaString = @".;?!:)";

// Title for action-sheet button for deleting text.
NSString *deleteTextTitleString = @"Delete This Text";

// Title for action-sheet button for editing text.
NSString *editTextTitleString = @"Edit Current Title and Text";

// Title for segmented-control segment for showing blanks (underscores).
NSString *blanksTextModeTitleString = @"Blanks";

// Title for segmented-control segment for showing full text.
NSString *fullTextModeTitleString = @"Full Text";

// Title for segmented control segment for showing nothing.
NSString *nothingTextModeTitleString = @"Nothing";

NSString *testWidthString = @"_abcdefghijklmnopqrstuvwxyzabcdefghijklm_";

// Private category for private methods.
@interface RootViewController ()

// Once we create this, we'll keep it in memory and just reuse it.
@property (nonatomic, retain) UIActionSheet *actionSheet;

// Segment in segmented control for switching to mode showing blanks.
@property (nonatomic) NSUInteger blanksSegmentIndex;

// Segment in segmented control for switching to full-text mode.
@property (nonatomic) NSUInteger fullTextSegmentIndex;

// Segment in segmented control for switching to mode showing nothing.
@property (nonatomic) NSUInteger nothingSegmentIndex;

// Once we create this, we'll keep it in memory and just reuse it.
@property (nonatomic, retain) UIPopoverController *popoverController;

// The string last shown in Blanks mode, for the current text.
@property (nonatomic, retain) NSString *previousBlanksModeString;

@property (nonatomic, retain) NSDate *previousSelectedRangeDate;

@property (nonatomic) NSUInteger previousSelectedRangeLocation;

// I.e., the previous text mode. 
@property (nonatomic) NSUInteger previousSelectedSegmentIndex;

@property (nonatomic, retain) RecordingAndPlaybackController *recordingAndPlaybackController;

// Date when the text view was single-tapped while in blanks mode.
@property (nonatomic, retain) NSDate *textViewSingleTapInBlanksModeDate;

// Date when the text view's selected range changed to the correct value.
@property (nonatomic, retain) NSDate *textViewSelectedRangeIsCorrectDate;

// Add a new text and show it.
- (void)addANewText;

// Start key-value observing.
- (void)addObservers;

// Delete the current text.
- (void)deleteCurrentText;

// If a popover is already showing, hide it immediately. (E.g., the user taps on one button, showing a popover, then immediately taps on another button, to show a different popover.) Includes action sheets displayed in a popover.
- (void)dismissAnyVisiblePopover;

// Go to editing view for the current text.
- (void)editCurrentText;

// If the user tapped the text view at the selected range, then we want to show or hide more words. (Assuming the user is in blanks mode.) However, a single tap in the text view will trigger a tap recognizer once and a selection change twice. Also, the recognizer may trigger before or after the selection changes. So, each tap and each selection change will call this method, and this method will first check whether the tap and current selection are consistent with what we expect.
- (void)handleTapAndSelectionChange;

// A single tap in the text view will trigger this method once and a selection change twice, but the order may vary. So check whether the selection change already happened correctly.
- (void)handleTextViewSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer;
    
// Given a text view, set its width to span the test string. Also, keep the view centered.
- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView;

// Stop key-value observing.
- (void)removeObservers;

// Create this view's popover controller, if necessary. Set the controller's content view controller.
- (void)setPopoverControllerContentViewController:(UIViewController *)theViewController;

// Show blanks/underscores for each word (plus punctuation). The same number of blanks should be shown for each word.
- (void)showBlanks;

// Show the entire text (vs. only first letters).
- (void)showFullText;

// The user tapped the text view at the selected range, to show more words or to hide visible words. If the selection is whitespace, then do nothing. If a blank, then show words from the start through the selection. If a letter, then hide words from (and including) the selection to the end.
- (void)showOrHideMoreWords;

// Return whether the text view's current selected range is correct.
- (BOOL)textViewSelectedRangeIsCorrect;

// Make sure the correct title and text is showing. (And that the text's mode is correct.)
- (void)updateTitleAndTextShowing;

@end

@implementation RootViewController

@synthesize addTextBarButtonItem, bottomToolbar, currentText, currentTextTextView, editTextBarButtonItem, recordBarButtonItem, textToShowSegmentedControl, titleLabel, topToolbar, trashBarButtonItem;
@synthesize actionSheet, blanksSegmentIndex, fullTextSegmentIndex, nothingSegmentIndex, popoverController, previousBlanksModeString, previousSelectedRangeDate, previousSelectedRangeLocation, previousSelectedSegmentIndex, recordingAndPlaybackController, textViewSingleTapInBlanksModeDate, textViewSelectedRangeIsCorrectDate;

- (void)actionSheet:(UIActionSheet *)theActionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	// Check the title of the button index. Act appropriately.
	if (buttonIndex != -1) {
		
		NSString *buttonTitle = [theActionSheet buttonTitleAtIndex:buttonIndex];
		if ( [buttonTitle isEqualToString:editTextTitleString] ) {
			
			[self editCurrentText];
		} else if ( [buttonTitle isEqualToString:addTextTitleString] ) {
			
			[self addANewText];
		} else if ( [buttonTitle isEqualToString:deleteTextTitleString] ) {
			
			[self deleteCurrentText];
		}
	}
}

- (void)addANewText {
	
	// Add text and save.
	TextMemoryAppDelegate *aTextMemoryAppDelegate = (TextMemoryAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aManagedObjectContext = [aTextMemoryAppDelegate managedObjectContext];
	Text *aText = (Text *)[NSEntityDescription insertNewObjectForEntityForName:@"Text" inManagedObjectContext:aManagedObjectContext];
	[aTextMemoryAppDelegate saveContext];
	
	// Show new text, fading into it.
	CATransition *aTransition = [CATransition animation];
	aTransition.duration = fadeTransitionDuration;
	[self.navigationController.view.layer addAnimation:aTransition forKey:nil];
	self.currentText = aText;
}

- (void)addObservers {
	
	// Watch for changes to the current text.
	[self addObserver:self forKeyPath:@"currentText" options:0 context:nil];
}

- (IBAction)changeTextModeToShow:(UISegmentedControl *)theSegmentedControl {
    
    if (self.previousSelectedSegmentIndex == self.blanksSegmentIndex) {
        
        self.previousBlanksModeString = self.currentTextTextView.text;
    }

	if (theSegmentedControl.selectedSegmentIndex == self.fullTextSegmentIndex) {
		
		[self showFullText];
        self.currentTextTextView.hidden = NO;
        self.currentTextTextView.editable = NO;
	} else if (theSegmentedControl.selectedSegmentIndex == self.blanksSegmentIndex) {
        
        [self showBlanks];
        self.currentTextTextView.hidden = NO;
        self.currentTextTextView.editable = YES;
    } else if (theSegmentedControl.selectedSegmentIndex == self.nothingSegmentIndex) {
		
		self.currentTextTextView.hidden = YES;
        self.currentTextTextView.editable = NO;
	} 
    self.previousSelectedSegmentIndex = theSegmentedControl.selectedSegmentIndex;
}

- (IBAction)confirmAddText:(id)sender {
    
    if (self.actionSheet.visible && (self.actionSheet.tag == 300) ) {
        
        [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    } else {
     
        [self dismissAnyVisiblePopover];
        
        // Ask user to confirm/choose via an action sheet.
        UIActionSheet *anActionSheet;
        anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:addTextTitleString, nil];
        [anActionSheet showFromBarButtonItem:self.addTextBarButtonItem animated:NO];
        anActionSheet.tag = 300;
        self.actionSheet = anActionSheet;
        [anActionSheet release];
	}
}

- (IBAction)confirmDeleteCurrentText:(id)sender {
	
    if (self.actionSheet.visible && (self.actionSheet.tag == 302) ) {
        
        [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    } else {
        
        [self dismissAnyVisiblePopover];
        
        // If a default text, tell why it can't be deleted. Else, ask user to confirm via an action sheet.
            
        UIActionSheet *anActionSheet;
        if ([self.currentText isDefaultData]) {
            
            anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Can't Delete Examples", nil];
            
            // Disable buttons. This action sheet is informational only.
            anActionSheet.userInteractionEnabled = NO;
            
        } else {
            
            anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:deleteTextTitleString otherButtonTitles:nil];
        }
        [anActionSheet showFromBarButtonItem:self.trashBarButtonItem animated:NO];
        anActionSheet.tag = 302;
        self.actionSheet = anActionSheet;
        [anActionSheet release];
    }
}

- (IBAction)confirmEditCurrentText:(id)sender {
	
    if (self.actionSheet.visible && (self.actionSheet.tag == 301) ) {
        
        [self.actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    } else {
        
        [self dismissAnyVisiblePopover];
        
        // If a default text, tell why it can't be edited. Else, ask user to confirm/choose via an action sheet.
        
        UIActionSheet *anActionSheet;
        if ([self.currentText isDefaultData]) {
            
            anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Can't Edit Examples", nil];
            
            // Disable buttons. This action sheet is informational only.
            anActionSheet.userInteractionEnabled = NO;
        } else {
            
            anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:editTextTitleString, nil];
        }
        [anActionSheet showFromBarButtonItem:self.editTextBarButtonItem animated:NO];
        anActionSheet.tag = 301;
        self.actionSheet = anActionSheet;
        [anActionSheet release];
    }
}

- (void)dealloc {
	
	[self removeObservers];
	
    [actionSheet release];
	self.popoverController.delegate = nil;
	[popoverController release];
    [previousBlanksModeString release];
    [previousSelectedRangeDate release];
    self.recordingAndPlaybackController.delegate = nil;
    [recordingAndPlaybackController release];
	[textViewSingleTapInBlanksModeDate release];
    [textViewSelectedRangeIsCorrectDate release];
    
	[introText_ release];
    
	[addTextBarButtonItem release];
	[bottomToolbar release];
	[currentText release];
	self.currentTextTextView.delegate = nil;
	[currentTextTextView release];
	[editTextBarButtonItem release];
    [recordBarButtonItem release];
	[textToShowSegmentedControl release];
	[titleLabel release];
	[topToolbar release];
	[trashBarButtonItem release];
	
	[super dealloc];
}

- (void)deleteCurrentText {
	
	// This has no visible transition, but it seems okay since the deletion action sheet takes some time to disappear.
	TextMemoryAppDelegate *aTextMemoryAppDelegate = (TextMemoryAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aManagedObjectContext = [aTextMemoryAppDelegate managedObjectContext];
	[aManagedObjectContext deleteObject:self.currentText];
	[aTextMemoryAppDelegate saveContext];
	
	self.currentText = [self introText];
}

- (void)didReceiveMemoryWarning {

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)dismissAnyVisiblePopover {
    
    if (self.popoverController.popoverVisible) {
        [self.popoverController dismissPopoverAnimated:NO];
    }
    if (self.actionSheet.visible) {
        [self.actionSheet dismissWithClickedButtonIndex:-1 animated:NO];
    }
}

- (void)editCurrentText {
	
	EditTextViewController *anEditTextViewController = [(EditTextViewController *)[EditTextViewController alloc] initWithText:self.currentText contentOffset:self.currentTextTextView.contentOffset font:self.currentTextTextView.font];
	anEditTextViewController.delegate = self;
	
	// Show the editing view. Instead of the navigation controller's transition, do a fade.
	CATransition *aTransition = [CATransition animation];
	aTransition.duration = fadeTransitionDuration;
	[self.navigationController.view.layer addAnimation:aTransition forKey:nil];
	[self.navigationController pushViewController:anEditTextViewController animated:NO];
	
	[anEditTextViewController release];
}

- (IBAction)editText:(id)sender {
	
	// If a default text, tell why it can't be edited. Else, proceed to editing view.
	
	if ([self.currentText isDefaultData]) {
	
		UIActionSheet *anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Can't Edit Examples", nil];
		
		// Disable buttons. This action sheet is informational only.
		anActionSheet.userInteractionEnabled = NO;
		
		[anActionSheet showFromBarButtonItem:self.editTextBarButtonItem animated:NO];
		[anActionSheet release];
	} else {
		
		EditTextViewController *anEditTextViewController = [(EditTextViewController *)[EditTextViewController alloc] initWithText:self.currentText contentOffset:self.currentTextTextView.contentOffset font:self.currentTextTextView.font];
		anEditTextViewController.delegate = self;
		
		// Show the editing view. Instead of the navigation controller's transition, do a fade.
		CATransition *aTransition = [CATransition animation];
		aTransition.duration = fadeTransitionDuration;
		[self.navigationController.view.layer addAnimation:aTransition forKey:nil];
		[self.navigationController pushViewController:anEditTextViewController animated:NO];
		
		[anEditTextViewController release];
	}
}

- (void)editTextViewControllerDidFinishEditing:(EditTextViewController *)sender {
	
	self.currentTextTextView.contentOffset = sender.contentOffset;
	[self updateTitleAndTextShowing];
}

- (void)fontSizeViewControllerDidChangeFontSize:(FontSizeViewController *)theFontSizeViewController {
	
	NSString *currentFontName = self.currentTextTextView.font.fontName;
	UIFont *newFont = [UIFont fontWithName:currentFontName size:theFontSizeViewController.currentFontSize];
	self.currentTextTextView.font = newFont;
	[self maintainRelativeWidthOfTextView:self.currentTextTextView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    // There is a custom single-tap gesture recognizer attached to the text view. Currently, it's the only gesture recognizer that has this class as its delegate. We want this recognizer to work with other tap recognizers inherent to the text view.
    
    BOOL answer = NO;
    if ( [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
        
       answer = YES;
    } 
    return answer;
}

- (void)handleTapAndSelectionChange {
    
    // Check whether there was an appropriate single tap. Check whether the current selected range is correct.
    if (self.textViewSingleTapInBlanksModeDate != nil && self.textViewSelectedRangeIsCorrectDate != nil) {
        
        // Check whether both happened recently.
        if ( ([self.textViewSingleTapInBlanksModeDate timeIntervalSinceNow] > -0.1) && ( [self.textViewSelectedRangeIsCorrectDate timeIntervalSinceNow] > -0.1) ) {
            
            [self showOrHideMoreWords];
        }
    }
}

- (void)handleTextViewSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.blanksSegmentIndex) {
        
        self.textViewSingleTapInBlanksModeDate = [NSDate date];
        [self handleTapAndSelectionChange];
    }
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
        // Custom initialization.
    }
    return self;
}

- (Text *)introText {
	
	if (introText_ != nil) {
        return introText_;
    }
	
	// Fetch initial text.
	NSManagedObjectContext *aManagedObjectContext = [(TextMemoryAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Text" inManagedObjectContext:aManagedObjectContext];
	[fetchRequest setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title MATCHES %@", welcomeTextTitle]; 
	[fetchRequest setPredicate:predicate];
	NSError *error = nil;
	NSArray *array = [aManagedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	if (array == nil) {
		NSLog(@"RVC: fetch failed?");
	}
	if (array.count == 0) {
		NSLog(@"Warning: RVC iT couldn't find a Text entitled '%@.'", welcomeTextTitle);
	} else {
		introText_ = [array objectAtIndex:0];
	}

	return introText_;
}

- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView {
	
	CGFloat newWidth = [testWidthString sizeWithFont:theTextView.font].width;
	
	// Width must be even to avoid subpixel boundaries.
	if ((int)newWidth % 2 != 0) {
		newWidth += 1;
	}
	
	CGRect newFrame = theTextView.frame;
	newFrame.size.width = newWidth;
	newFrame.origin.x = (self.view.frame.size.width - newFrame.size.width) / 2;
	theTextView.frame = newFrame;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	// If the current text changed, then update the view's title and text.
	if ([keyPath isEqualToString:@"currentText"]) {
		
		[self updateTitleAndTextShowing];
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	
	// Re-enable corresponding toolbar. (Currently, the only popover controller that should call this method is for the Texts button.)
	//self.topToolbar.userInteractionEnabled = YES;
}

- (void)recordingAndPlaybackControllerDidPauseRecording:(RecordingAndPlaybackController *)theRecordingAndPlaybackController {
    
    self.recordBarButtonItem.title = @"Recording: Paused";
}

- (void)recordingAndPlaybackControllerDidStartPlaying:(RecordingAndPlaybackController *)recordingAndPlaybackController {
    
    self.recordBarButtonItem.title = @"Recording: Playing";
}

- (void)recordingAndPlaybackControllerDidStartRecording:(RecordingAndPlaybackController *)recordingAndPlaybackController {
    
    self.recordBarButtonItem.title = @"Recording: On";
}

- (void)recordingAndPlaybackControllerDidStopPlaying:(RecordingAndPlaybackController *)recordingAndPlaybackController {
    
    self.recordBarButtonItem.title = @"Recording: Off";
}

- (void)recordingAndPlaybackControllerDidStopRecording:(RecordingAndPlaybackController *)recordingAndPlaybackController {
    
    self.recordBarButtonItem.title = @"Recording: Off";
}

- (void)removeObservers {
	
	[self removeObserver:self forKeyPath:@"currentText"];
}

- (void)setPopoverControllerContentViewController:(UIViewController *)theViewController {
    
    if (!self.popoverController) {
        
        UIPopoverController *aPopoverController = [[UIPopoverController alloc] initWithContentViewController:theViewController];
        aPopoverController.delegate = self;
        aPopoverController.passthroughViews = [NSArray arrayWithObject:self.textToShowSegmentedControl];
        self.popoverController = aPopoverController;
        [aPopoverController release];
    } else {
        self.popoverController.contentViewController = theViewController;
    }
    
    // Resize popover.
    self.popoverController.popoverContentSize = self.popoverController.contentViewController.contentSizeForViewInPopover;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Overriden to allow any orientation.
    return YES;
}

- (void)showBlanks {
    
    if (self.previousBlanksModeString != nil) {
        
        self.currentTextTextView.text = self.previousBlanksModeString;
    } else {
        
        self.currentTextTextView.text = [self.currentText blanksText];
    }
}

- (IBAction)showFontSizePopover:(id)sender {
    
    // If this popover is visible, then hide it slowly. Else, hide any other popover immediately and show this one.
    if (self.popoverController.popoverVisible && [self.popoverController.contentViewController isKindOfClass:[FontSizeViewController class] ]) {
        
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        
        [self dismissAnyVisiblePopover];
		
		// Create the view controller for the popover.
		FontSizeViewController *aFontSizeViewController = [[FontSizeViewController alloc] init];
		aFontSizeViewController.delegate = self;
		aFontSizeViewController.currentFontSize = self.currentTextTextView.font.pointSize;
        
		// Present popover.
		[self setPopoverControllerContentViewController:aFontSizeViewController];
		[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}	
}

- (void)showFullText {
	
	self.currentTextTextView.text = self.currentText.text;
}

- (void)showOrHideMoreWords {
    
    // If the location is whitespace, do nothing.
    // Update: Text view will automatically move the caret to the start or end of a word. So, if the location is whitespace, check location - 1. If that is not whitespace, then proceed with the selected index at location - 1.
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSUInteger selectedIndex = self.currentTextTextView.selectedRange.location;
    unichar aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
    if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar] && (selectedIndex != 0) ) {
        
        selectedIndex = selectedIndex - 1;
        aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
        if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar]) {
            
            return;
        }
    }
    
    // The resulting text will have some full text followed by some blanks. Determine the index of the start of the blanks. Then assemble the text.
    
    // We show or hide by word, not character. So we need the range of the selection's word.
    NSRange selectedWordRange = [self.currentTextTextView.text rangeOfWordAtIndex:selectedIndex];
    
    // If the selected word has blanks, then everything up to and including that word will be shown, so the first blank will be the start of the next word. If the selected word doesn't have blanks, then that word and everything after will be hidden, so the first blank will be the start of that word. 
    NSUInteger startOfBlanksInTextViewTextIndex;
    NSString *selectedWord = [self.currentTextTextView.text substringWithRange:selectedWordRange];
    BOOL selectedWordHasBlanks = NO;
    if ([selectedWord rangeOfString:@"_"].location != NSNotFound) {
        
        selectedWordHasBlanks = YES;
    }
    if (selectedWordHasBlanks) {
        
        // First letter in word after selected word.
        startOfBlanksInTextViewTextIndex = [self.currentTextTextView.text startOfNthWord:1 afterRange:selectedWordRange];
        
    } else {
        
        // First letter in selected word.
        startOfBlanksInTextViewTextIndex = selectedWordRange.location;
    }
    
    // Determine the number of words in text up to the first blank. Get that many words from the full text. For the blanks, go past the number of words, then get the remaining blanks.
    
    NSUInteger nonBlankWordsUInteger = [[self.currentTextTextView.text substringToIndex:startOfBlanksInTextViewTextIndex] wordCount];
    NSUInteger startOfBlanksMappedToFullTextIndex = [self.currentText.text startOfNthWord:(nonBlankWordsUInteger + 1)];
    NSString *fullTextSubstring = [self.currentText.text substringToIndex:startOfBlanksMappedToFullTextIndex];
    NSMutableString *newTextMutableString = [NSMutableString stringWithString:fullTextSubstring];
    NSUInteger startOfBlanksMappedToBlanksTextIndex = [[self.currentText blanksText] startOfNthWord:(nonBlankWordsUInteger + 1)];
    NSString *blanksSubstring = [[self.currentText blanksText] substringFromIndex:startOfBlanksMappedToBlanksTextIndex];
    [newTextMutableString appendString:blanksSubstring];
    
    self.currentTextTextView.text = newTextMutableString;
    [self.currentTextTextView scrollRangeToVisible:NSMakeRange(fullTextSubstring.length, 0)];
}

- (IBAction)showRecordingPopover:(id)sender {
    
    // Careful here. Checking that popover's view controller is a nav controller. If we have multiple popovers that contain nav controllers, then we'll need another way to discriminate.
    if (self.popoverController.popoverVisible && [self.popoverController.contentViewController isKindOfClass:[UINavigationController class] ]) {
        
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        
        [self dismissAnyVisiblePopover];
        
        // Check if the view controller exists. If not, make it.
        if (self.recordingAndPlaybackController == nil) {
            
            RecordingAndPlaybackController *aRecordingAndPlaybackController = [[RecordingAndPlaybackController alloc] init];
            aRecordingAndPlaybackController.delegate = self;
            self.recordingAndPlaybackController = aRecordingAndPlaybackController;
            [aRecordingAndPlaybackController release];
        }
		
		// Present popover.
		[self setPopoverControllerContentViewController:self.recordingAndPlaybackController.navigationController];
		[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}    
}

- (IBAction)showTextsPopover:(id)sender {
	
    if (self.popoverController.popoverVisible && [self.popoverController.contentViewController isKindOfClass:[TextsTableViewController class] ]) {
        
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        
        [self dismissAnyVisiblePopover];
			
		// Create the view controller for the popover.
		TextsTableViewController *aTextsTableViewController = [[TextsTableViewController alloc] init];
		aTextsTableViewController.delegate = self;
		aTextsTableViewController.currentText = self.currentText;
		
		// Present popover.
		[self setPopoverControllerContentViewController:aTextsTableViewController];
		[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}	
}

- (void)textsTableViewControllerDidSelectText:(TextsTableViewController *)sender {
	
	[self.popoverController dismissPopoverAnimated:YES];
	
	// Dismissing popover programmatically doesn't call this delegate method. But we do cleanup there, so we need to call it.
	[self popoverControllerDidDismissPopover:nil];
	
    self.previousBlanksModeString = nil;
	self.currentText = sender.currentText;
}

- (void)textViewDidChangeSelection:(UITextView *)theTextView {
	
    // In blanks mode, the text view is editable to allow a single tap to set the selection range. But we don't want the keyboard to show up, so we'll always resign the first responder.
    if ( (self.textToShowSegmentedControl.selectedSegmentIndex == blanksSegmentIndex) && self.currentTextTextView.isFirstResponder) {
        
        [self.currentTextTextView resignFirstResponder];
    }
    
    // Sometimes the selected range will be beyond the end of the text. In that case, do nothing.
    if (self.currentTextTextView.selectedRange.location >= self.currentTextTextView.text.length) {
        
        return;
    }
    
    if ([self textViewSelectedRangeIsCorrect]) {
        
        if (self.textToShowSegmentedControl.selectedSegmentIndex == self.blanksSegmentIndex) {

            self.textViewSelectedRangeIsCorrectDate = [NSDate date];
            [self handleTapAndSelectionChange];
        }
    } else {
        
        self.textViewSelectedRangeIsCorrectDate = nil;
    }
    self.previousSelectedRangeLocation = self.currentTextTextView.selectedRange.location;
    self.previousSelectedRangeDate = [NSDate date];
}

- (BOOL)textViewSelectedRangeIsCorrect {
    
    // When user single-taps in the text view, textViewDidChangeSelection is called twice. The first time, the selected range is the text length (in iOS 4.3) or the previous range (in iOS 5.0+). The second time, the selected range is correct (i.e., where the tap was). So we want to ignore the first textViewDidChangeSelection. (If user double-taps, then textViewDidChangeSelection is called four times, with the correct range the last three times.)

    // Assume selected ranges outside the text range were already ignored. 
    // If the user taps once and later taps elsewhere, then the previous range will be detected once and the new range will be detected immediately after.
    // If the user taps once and later taps in exactly the same place, then the previous range will be detected twice, with the second time immediately after the first. 
    // So, we'll check if the current range is identical to the previous range. If so, the current range is incorrect. The exception is if the current range change happened immediately after the previous range change (e.g., < 0.1 seconds).
    
    BOOL answer = YES;
    if (self.currentTextTextView.selectedRange.location == self.previousSelectedRangeLocation) {
        
        answer = NO;
        NSTimeInterval timeSincePreviousSelectedRange = [ [NSDate date] timeIntervalSinceDate:self.previousSelectedRangeDate];
        if (timeSincePreviousSelectedRange < 0.1) {
            
            answer = YES;
        }
    }
    return answer;
}

- (void)updateTitleAndTextShowing {
	
	self.titleLabel.text = self.currentText.title;
    self.previousBlanksModeString = nil;
	if (self.textToShowSegmentedControl.selectedSegmentIndex == self.blanksSegmentIndex) {
        
        [self showBlanks];
    } else {
        
		[self showFullText];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
	
	if (createLaunchImages) {
		
		self.topToolbar.items = nil;
		self.titleLabel.text = @"";
		self.currentTextTextView.text = @"";
		self.bottomToolbar.items = nil;
	} else {

        UIColor *aLightBlueColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
        self.topToolbar.tintColor = aLightBlueColor;
        self.bottomToolbar.tintColor = aLightBlueColor;
        
		// Start KVO. 
		[self addObservers];
		
		// Set up segmented control for showing first letters.
		self.fullTextSegmentIndex = 0;
        self.blanksSegmentIndex = 1;
		self.nothingSegmentIndex = 2;
        [self.textToShowSegmentedControl setTitle:fullTextModeTitleString forSegmentAtIndex:self.fullTextSegmentIndex];
        [self.textToShowSegmentedControl setTitle:blanksTextModeTitleString forSegmentAtIndex:self.blanksSegmentIndex];
		[self.textToShowSegmentedControl setTitle:nothingTextModeTitleString forSegmentAtIndex:self.nothingSegmentIndex];
		
        /*
		// Add overlay view on top of all views.
		CGRect windowMinusBarsFrame = CGRectMake(0, self.currentTextTextView.frame.origin.y, self.view.frame.size.width, self.currentTextTextView.frame.size.height);
		OverlayView *anOverlayView = [[OverlayView alloc] initWithFrame:windowMinusBarsFrame];
		anOverlayView.textViewToIgnore = self.currentTextTextView;
		[self.view addSubview:anOverlayView];
         */
        
		// Align text view so it doesn't appear to shift later.
		[self maintainRelativeWidthOfTextView:self.currentTextTextView];
		
		// Set initial text.
		self.currentText = [self introText];
		
		// Set text view's delegate.
		self.currentTextTextView.delegate = self;
        
        // Add gesture recognizer: Single tap in text view.
        UITapGestureRecognizer *aSingleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextViewSingleTapGesture:)];
		aSingleTapGestureRecognizer.numberOfTapsRequired = 1;
        aSingleTapGestureRecognizer.delegate = self;
        [self.currentTextTextView addGestureRecognizer:aSingleTapGestureRecognizer];
		[aSingleTapGestureRecognizer release];
	}
}

- (void)viewDidUnload {
	
    [super viewDidUnload];
    
	[self removeObservers];
	
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.actionSheet.delegate = nil;
    self.actionSheet = nil;
	
    self.popoverController.delegate = nil;
	self.popoverController = nil;
    
    self.recordingAndPlaybackController.delegate = nil;
    self.recordingAndPlaybackController = nil;
    
	self.addTextBarButtonItem = nil;
	self.bottomToolbar = nil;
	self.currentTextTextView.delegate = nil;
	self.currentTextTextView = nil;
	self.editTextBarButtonItem = nil;
    self.recordBarButtonItem = nil;
	self.textToShowSegmentedControl = nil;
	self.titleLabel = nil;
	self.topToolbar = nil;
	self.trashBarButtonItem = nil;
}

@end


