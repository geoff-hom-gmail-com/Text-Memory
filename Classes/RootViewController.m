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

// The date of the last selection change in the text view.
@property (nonatomic, retain) NSDate *previousSelectedRangeDate;

// I.e., the previous text mode. 
@property (nonatomic) NSUInteger previousSelectedSegmentIndex;

@property (nonatomic, retain) RecordingAndPlaybackController *recordingAndPlaybackController;

// Date when the text view was last single-tapped while in Blanks mode.
@property (nonatomic, retain) NSDate *textViewSingleTapInBlanksModeDate;

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

// If the user tapped the text view at the selected range, then we want to show or hide more words. (Assuming the user is in blanks mode.) However, a single tap in the text view will trigger a tap recognizer and a selection change, in unknown order. Both the tap and the selection change should call this method. Then check whether they occurred at approximately the same time. If so, proceed.
- (void)handleTapAndSelectionChange;

// Upon view load, we want to load the input view immediately. Otherwise, it will cause a noticeable delay later. We'll have it appear and disappear immediately. Here, we assume the text view became first responder, the input view loaded, and the input view has or will appear.
- (void)handleTextViewBecameFirstResponderOnLoad;

// A single tap in the text view will trigger this method once and a selection change twice, but the order may vary. So check whether the selection change already happened.
- (void)handleTextViewSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer;
    
// Given a text view, set its width to span the test string. Also, keep the view centered.
- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView;

// Stop key-value observing.
- (void)removeObservers;

// Create this view's popover controller, if necessary. Set the controller's content view controller.
- (void)setPopoverControllerContentViewController:(UIViewController *)theViewController;

// Show blanks/underscores for each word (plus punctuation). 
- (void)showBlanks;

// Show the entire text (vs. blanks).
- (void)showFullText;

// The user tapped the text view at the selected range, to show more words or to hide visible words. If the selection is whitespace, then do nothing. If a blank, then show words from the start through the selection. If a letter, then hide words from (and including) the selection to the end.
- (void)showOrHideMoreWords;

// Make sure the correct title and text is showing. (And that the text's mode is correct.)
- (void)updateTitleAndTextShowing;

@end

@implementation RootViewController

@synthesize addTextBarButtonItem, bottomToolbar, currentText, currentTextTextView, editTextBarButtonItem, recordBarButtonItem, textToShowSegmentedControl, titleLabel, topToolbar, trashBarButtonItem;
@synthesize actionSheet, blanksSegmentIndex, fullTextSegmentIndex, nothingSegmentIndex, popoverController, previousBlanksModeString, previousSelectedRangeDate, previousSelectedSegmentIndex, recordingAndPlaybackController, textViewSingleTapInBlanksModeDate;

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
    if ( (self.textViewSingleTapInBlanksModeDate != nil) && 
        (self.previousSelectedRangeDate != nil) ) {
                
        // Check whether both happened recently.
        if ( ([self.textViewSingleTapInBlanksModeDate timeIntervalSinceNow] > -0.1) && 
            ( [self.previousSelectedRangeDate timeIntervalSinceNow] > -0.1) ) {
            
            [self showOrHideMoreWords];
        }
    }
}

- (void)handleTextViewBecameFirstResponderOnLoad {
    
    [self.currentTextTextView resignFirstResponder];
    
    // Assume the view loads in full-text mode, which is not supposed to be editable. 
    self.currentTextTextView.editable = NO;
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
    
    // For testing. If x or y is not an integer, then we're drawing on a subpixel boundary, and the text will be blurry.
    //NSLog(@"RVC mRWOTV: %@", NSStringFromCGRect(newFrame));
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
    // Update: Text view will automatically move the caret to the start or end of a word. So, if the location is the end of the text or whitespace, check location - 1. If that is not whitespace, then proceed with the selected index at location - 1.
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSUInteger selectedIndex = self.currentTextTextView.selectedRange.location;
    unichar aChar;
    if (selectedIndex == 0) {
        
    } else if (selectedIndex == self.currentTextTextView.text.length) {
        
        selectedIndex = selectedIndex - 1;
    } else {
        
        aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
        if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar]) {
            
            selectedIndex = selectedIndex - 1;
        }
    }
    aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
    if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar]) {
            
        return;
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
    
    // When showing more words, the current text may get much larger, so the selected range will no longer be visible. We'll scroll down so that the selected range (transition from words to blanks) is visible.
    
    // We want to scroll a couple lines past the selected range, so it won't be on the very bottom. The text view's width is maintained at a character width: 26 + 13 + 2 = 41. So a couple lines should be 82 characters more. 
    // If the range is past the length, then the text view won't scroll.
    NSUInteger twoLinesAfterFirstBlankIndex = MIN(fullTextSubstring.length + 82, self.currentTextTextView.text.length);
    NSRange twoLinesAfterFirstBlankRange = NSMakeRange(twoLinesAfterFirstBlankIndex, 0);
    [self.currentTextTextView scrollRangeToVisible:twoLinesAfterFirstBlankRange];
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
    self.currentTextTextView.contentOffset = CGPointMake(0, 0);
}

- (void)textViewDidChangeSelection:(UITextView *)theTextView {
    
    //NSLog(@"RVC tVDCS selectedRange:%@", NSStringFromRange(self.currentTextTextView.selectedRange));
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.blanksSegmentIndex) {
	
        // In blanks mode, the text view is editable to allow a single tap to set the selection range. But we don't want the keyboard to show up, so we'll always resign the first responder.
        if (self.currentTextTextView.isFirstResponder) {
            
            [self.currentTextTextView resignFirstResponder];
        }
        
        // When the user taps in the text view, textViewDidChangeSelection is called twice, in quick succession. We want to ignore the first time. So, when a selection change occurs, note when. If the previous change just occurred, then keep going.
        
        NSDate *aDate = [NSDate date];
        NSTimeInterval timeSincePreviousSelectedRange = [aDate timeIntervalSinceDate:self.previousSelectedRangeDate];
        self.previousSelectedRangeDate = aDate;
        
        // This value is important. Note that the simulator is usually much faster than the device. But even in the simulator, a double-tap takes at least 0.17 seconds. On the device, the second selection change should be within 0.10 seconds.
        if (timeSincePreviousSelectedRange < 0.10) {
            
            [self handleTapAndSelectionChange];
        }
    }
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
		self.titleLabel.text = @"Text Memory";
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
        
        // The user can tap a word to show or hide more words. The tapped word is determined by the text view's selected range. The selected range is updated only if the text view is editable. When the user taps the editable text view, the keyboard appears. The first time this happens, there is a noticeable (~1 second) delay. To circumvent this, we'll make the keyboard appear and disappear right away, so the delay will be part of the initial load. However, on the device, the keyboard still appears for a split second. So we'll also replace the keyboard with a hidden dummy view.
        
        CGRect tinyFrameRect = CGRectMake(0, 0, 0, 0);
        UIView *aDummyInputView = [[UIView alloc] initWithFrame:tinyFrameRect];
        aDummyInputView.autoresizingMask = UIViewAutoresizingNone;
        aDummyInputView.hidden = YES;
        self.currentTextTextView.inputView = aDummyInputView;
        [aDummyInputView release];
        
        // Calling resignFirstResponder right away doesn't always work. But calling it after an immediate timer does.
        self.currentTextTextView.editable = YES;
        [self.currentTextTextView becomeFirstResponder];
        [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(handleTextViewBecameFirstResponderOnLoad) userInfo:nil repeats:NO];
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
    self.currentTextTextView.inputView = nil;
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


