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

// Title for segmented control segment for showing full text.
NSString *fullTextModeTitleString = @"Full Text";

// Title for segmented control segment for showing nothing.
NSString *nothingTextModeTitleString = @"Nothing";

NSString *testWidthString = @"_abcdefghijklmnopqrstuvwxyzabcdefghijklm_";

// Title for segmented control segment for showing the same number of blanks per word.
NSString *uniBlanksTextModeTitleString = @"UniBlanks";

// Private category for private methods.
@interface RootViewController ()

// Once we create this, we'll keep it in memory and just reuse it.
@property (nonatomic, retain) UIActionSheet *actionSheet;

// In Blanks mode, the string index up through which the full text was last shown.
@property (nonatomic) NSUInteger blanksModeLocationToShowThrough;

// Segment in segmented control for switching to first-letter mode.
@property (nonatomic) NSUInteger firstLettersSegmentIndex;

// Segment in segmented control for switching to full-text mode.
@property (nonatomic) NSUInteger fullTextSegmentIndex;

// Segment in segmented control for switching to mode showing nothing.
@property (nonatomic) NSUInteger nothingSegmentIndex;

// Once we create this, we'll keep it in memory and just reuse it.
@property (nonatomic, retain) UIPopoverController *popoverController;

// The string last shown in "Blanks" mode, for the current text.
@property (nonatomic, retain) NSString *previousBlanksModeString;

@property (nonatomic, retain) NSDate *previousSelectedRangeDate;

@property (nonatomic) NSUInteger previousSelectedRangeLocation;

// I.e., the previous text mode. 
@property (nonatomic) NSUInteger previousSelectedSegmentIndex;

// The string last shown in uni-blanks mode, for the current text.
@property (nonatomic, retain) NSString *previousUniBlankModeString;

@property (nonatomic, retain) RecordingAndPlaybackController *recordingAndPlaybackController;

// Date when the text view was single-tapped while in first-letter mode.
@property (nonatomic, retain) NSDate *textViewSingleTapInFirstLetterModeDate;

// Date when the text view's selected range changed to the correct value.
@property (nonatomic, retain) NSDate *textViewSelectedRangeIsCorrectDate;

// Segment in segmented control for switching to mode showing the same number of blanks per word.
@property (nonatomic) NSUInteger uniBlanksSegmentIndex;

// Add a new text and show it.
- (void)addANewText;

// Start key-value observing.
- (void)addObservers;

// Delete the current text.
- (void)deleteCurrentText;

// If a popover is already showing, hide it immediately. (E.g., the user taps on one button, showing a popover, then immediately taps on another button, to show a different popover.) Includes action sheets displayed in a popover.
- (void)dismissAnyVisiblePopover;

// The user tapped at the selected range. Either do nothing, reveal text, or hide text.
- (void)doSomethingAtSelectedRange;

// Go to editing view for the current text.
- (void)editCurrentText;

- (void)hideFullTextForSelectedClause;

// Given a text view, set its width to span the test string. Also, keep the view centered.
- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView;

// Stop key-value observing.
- (void)removeObservers;

// Create this view's popover controller, if necessary. Set the controller's content view controller.
- (void)setPopoverControllerContentViewController:(UIViewController *)theViewController;

// Return whether to show the full text for the text view's selection. Should return YES if the user double-tapped on a word while in first-letter mode.
- (BOOL)shouldShowFullTextForSelection;

// Show the entire text (vs. only first letters).
- (void)showFullText;

- (void)showFullTextForSelectedClause;

// Show the entire text for the text view's current selection (in first-letter mode), expanding to at least a word.
- (void)showFullTextForSelection;

// Show only underscores for each word (plus punctuation).
- (void)showUnderscoresOnly;

// Show the same number of underscores for each word (plus punctuation).
- (void)showUniBlanks;

// Return whether the text view's current selected range is correct.
- (BOOL)textViewSelectedRangeIsCorrect;

// ?
// assume selectedWordRange is in a word (i.e. not whitespace)
- (void)uniBlanksModeShowOrHideWords:(NSRange)selectedWordRange;

// Make sure the correct title and text is showing. (And that the text's mode is correct.)
- (void)updateTitleAndTextShowing;

@end

@implementation RootViewController

@synthesize addTextBarButtonItem, bottomToolbar, currentText, currentTextTextView, editTextBarButtonItem, recordBarButtonItem, textToShowSegmentedControl, titleLabel, topToolbar, trashBarButtonItem;
@synthesize actionSheet, blanksModeLocationToShowThrough, firstLettersSegmentIndex, fullTextSegmentIndex, nothingSegmentIndex, popoverController, previousBlanksModeString, previousSelectedRangeDate, previousSelectedRangeLocation, previousSelectedSegmentIndex, previousUniBlankModeString, recordingAndPlaybackController, textViewSingleTapInFirstLetterModeDate, textViewSelectedRangeIsCorrectDate, uniBlanksSegmentIndex;

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
	
	// Re-enable toolbars, in case they were disabled.
//	self.topToolbar.userInteractionEnabled = YES;
//	self.bottomToolbar.userInteractionEnabled = YES;
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
    
    if (self.previousSelectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        self.previousBlanksModeString = self.currentTextTextView.text;
    } else if (self.previousSelectedSegmentIndex == self.uniBlanksSegmentIndex) {
        
        self.previousUniBlankModeString = self.currentTextTextView.text;
        //self.previousVisibleRange = ??;
    } else if (self.previousSelectedSegmentIndex == self.fullTextSegmentIndex) {
        
        //self.previousVisibleRange = ??;
    }

	if (theSegmentedControl.selectedSegmentIndex == self.fullTextSegmentIndex) {
		
		[self showFullText];
        self.currentTextTextView.hidden = NO;
        self.currentTextTextView.editable = NO;
        
        // Adjust content offset to match full-text offset.
        //[self.currentTextTextView scrollRangeToVisible:self.previousVisibleRange];
	} else if (theSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
		
		[self showUnderscoresOnly];
        self.currentTextTextView.hidden = NO;
        self.currentTextTextView.editable = YES;
	} else if (theSegmentedControl.selectedSegmentIndex == self.nothingSegmentIndex) {
		
		self.currentTextTextView.hidden = YES;
        self.currentTextTextView.editable = NO;
	} else if (theSegmentedControl.selectedSegmentIndex == self.uniBlanksSegmentIndex) {
        
        [self showUniBlanks];
        self.currentTextTextView.hidden = NO;
        self.currentTextTextView.editable = YES;
        
        // Adjust content offset to match full-text offset.
        //[self.currentTextTextView scrollRangeToVisible:self.previousVisibleRange];
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

// Determine if we should do something at the selected range. There must have been a single-tap at the selected range.
- (void)considerDoingSomethingAtSelectedRange {
    
    // Check whether there was an appropriate single tap. Check whether the current selected range is correct.
    if (self.textViewSingleTapInFirstLetterModeDate != nil && self.textViewSelectedRangeIsCorrectDate != nil) {
        
        // Check whether both happened recently.
        if ( ([self.textViewSingleTapInFirstLetterModeDate timeIntervalSinceNow] > -0.1) && ( [self.textViewSelectedRangeIsCorrectDate timeIntervalSinceNow] > -0.1) ) {
            
            //NSLog(@"Do something at selected range:|%@|", NSStringFromRange(self.currentTextTextView.selectedRange) );
            [self doSomethingAtSelectedRange];
        }
    }
}

- (void)dealloc {
	
	[self removeObservers];
	
    [actionSheet release];
	self.popoverController.delegate = nil;
	[popoverController release];
    [previousBlanksModeString release];
    [previousSelectedRangeDate release];
    [previousUniBlankModeString release];
    self.recordingAndPlaybackController.delegate = nil;
    [recordingAndPlaybackController release];
	[textViewSingleTapInFirstLetterModeDate release];
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

- (void)blanksModeShowOrHideWords:(NSUInteger)selectedIndex {
    
    // If the location is in a word with underscores, then reveal the full text up through that word.
    // If the location is in a word without underscores (i.e. full text), then show underscores (i.e., hide text) from (and including) that word to the end.
    // To detect underscores, we'll first search forward and backward until whitespace to get the word range.
    
    // Check from selected index to end. Since we want the end of the word and not actual whitespace, subtract one from the end.
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSRange rangeToCheck = NSMakeRange(selectedIndex, self.currentTextTextView.text.length - selectedIndex);
    NSRange endOfWordRange = [self.currentTextTextView.text rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:0 range:rangeToCheck];
    if (endOfWordRange.location == NSNotFound) {
        
        endOfWordRange.location = self.currentTextTextView.text.length - 1;
    } else {
        
        endOfWordRange.location = endOfWordRange.location - 1;
    }
    
    // Check from start up to selected index. Since we want the start of the word and not actual whitespace, add one to the start.
    rangeToCheck = NSMakeRange(0, selectedIndex);
    NSRange startOfWordRange = [self.currentTextTextView.text rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:NSBackwardsSearch range:rangeToCheck];
    if (startOfWordRange.location == NSNotFound) {
        
        startOfWordRange.location = 0;
    } else {
        
        startOfWordRange.location = startOfWordRange.location + 1;
    }
    
    NSRange wordRange = NSMakeRange(startOfWordRange.location, endOfWordRange.location - startOfWordRange.location + 1);
    NSLog(@"word range:%@", NSStringFromRange(wordRange) );
    NSCharacterSet *underscoreCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    NSRange underscoreRange = [self.currentTextTextView.text rangeOfCharacterFromSet:underscoreCharacterSet options:0 range:wordRange];
    NSRange targetRange;
    NSString *newString;
    NSString *textWithReplacementString;
    if (underscoreRange.location == NSNotFound) {
        
        // Show underscores from word through end.
        NSLog(@"hide text");
        
        targetRange = NSMakeRange(wordRange.location, self.currentTextTextView.text.length - wordRange.location);
        newString = [self.currentText.underscoreText substringWithRange:targetRange];
        textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:targetRange withString:newString];
        self.currentTextTextView.text = textWithReplacementString;
        
        // Set selected range to start of word.
        //self.currentTextTextView.selectedRange = NSMakeRange(wordRange.location, 0);
        
        // Keep track of range to show.
        NSInteger locationToShowThrough = wordRange.location - 2;
        if (locationToShowThrough < 0) {
            
            self.blanksModeLocationToShowThrough = NSNotFound;
        } else {
            
            self.blanksModeLocationToShowThrough = wordRange.location;
        }
    } else {
        
        // Show full text from start up through word.
        NSLog(@"reveal text");
        
        targetRange = NSMakeRange(0, endOfWordRange.location + 1);
        newString = [self.currentText.text substringWithRange:targetRange];
        textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:targetRange withString:newString];
        
        self.currentTextTextView.text = textWithReplacementString;
        
        // Set selected range to just after end of word.
        
        NSUInteger startOfNextWhitespace = endOfWordRange.location + 1;
        if (startOfNextWhitespace == self.currentTextTextView.text.length) {
            
            startOfNextWhitespace = startOfNextWhitespace - 1;
        }
        //self.currentTextTextView.selectedRange = NSMakeRange(startOfNextWhitespace, 0);
        
        // Keep track of range to show.
        self.blanksModeLocationToShowThrough = endOfWordRange.location;
    }
}

- (void)uniBlanksModeShowOrHideWords:(NSRange)selectedWordRange {
    
    // The resulting text will have some full text followed by some uni-blank text. Determine the index of the start of the uni-blank text. Then assemble the text.
    
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
    
    // Determine number of words in text up to the first blank. Get that many words from the full text. For the uni-blank text, go past that many words, then get the rest of the uni-blank text.
    
    NSUInteger nonBlankWordsUInteger = [[self.currentTextTextView.text substringToIndex:startOfBlanksInTextViewTextIndex] wordCount];
    NSUInteger startOfBlanksMappedToFullTextIndex = [self.currentText.text startOfNthWord:(nonBlankWordsUInteger + 1)];
    NSString *fullTextSubstring = [self.currentText.text substringToIndex:startOfBlanksMappedToFullTextIndex];
    NSMutableString *newTextMutableString = [NSMutableString stringWithString:fullTextSubstring];
    NSUInteger startOfBlanksMappedToUniBlankTextIndex = [[self.currentText getUniBlankText] startOfNthWord:(nonBlankWordsUInteger + 1)];
    NSString *uniBlankSubstring = [[self.currentText getUniBlankText] substringFromIndex:startOfBlanksMappedToUniBlankTextIndex];
    [newTextMutableString appendString:uniBlankSubstring];
    
    self.currentTextTextView.text = newTextMutableString;
    [self.currentTextTextView scrollRangeToVisible:NSMakeRange(fullTextSubstring.length, 0)];
}

- (void)doSomethingAtSelectedRange {
    
    // If the location is whitespace, do nothing.
    // Update: Text view will automatically move the caret to the start or end of a word. So, if the location is whitespace, check location - 1. If that is not whitespace, then proceed with the selected index at location - 1.
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSUInteger selectedIndex = self.currentTextTextView.selectedRange.location;
    unichar aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
    //NSLog(@"dSASR range:%@ aChar:%@", NSStringFromRange(self.currentTextTextView.selectedRange), [NSString stringWithCharacters:&aChar length:1] );
    
    if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar] && (selectedIndex != 0) ) {
            
        selectedIndex = selectedIndex - 1;
        aChar = [self.currentTextTextView.text characterAtIndex:selectedIndex];
        if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar]) {
            
            return;
        }
    }
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        [self blanksModeShowOrHideWords:selectedIndex];
    } else if (self.textToShowSegmentedControl.selectedSegmentIndex == self.uniBlanksSegmentIndex) {
        
        NSRange selectedWordRange = [self.currentTextTextView.text rangeOfWordAtIndex:selectedIndex];
        [self uniBlanksModeShowOrHideWords:selectedWordRange];
    }
    
    /*
    
    // If the location is in a word with underscores, then reveal the full text up through that word.
    // If the location is in a word without underscores (i.e. full text), then show underscores (i.e., hide text) from (and including) that word to the end.
    // To detect underscores, we'll first search forward and backward until whitespace to get the word range.
    
    // Check from selected index to end. Since we want the end of the word and not actual whitespace, subtract one from the end.
    NSRange rangeToCheck = NSMakeRange(selectedIndex, self.currentTextTextView.text.length - selectedIndex);
    NSRange endOfWordRange = [self.currentTextTextView.text rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:0 range:rangeToCheck];
    if (endOfWordRange.location == NSNotFound) {
        
        endOfWordRange.location = self.currentTextTextView.text.length - 1;
    } else {
        
        endOfWordRange.location = endOfWordRange.location - 1;
    }
    
    // Check from start up to selected index. Since we want the start of the word and not actual whitespace, add one to the start.
    rangeToCheck = NSMakeRange(0, selectedIndex);
    NSRange startOfWordRange = [self.currentTextTextView.text rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:NSBackwardsSearch range:rangeToCheck];
    if (startOfWordRange.location == NSNotFound) {
        
        startOfWordRange.location = 0;
    } else {
        
        startOfWordRange.location = startOfWordRange.location + 1;
    }
    
    NSRange wordRange = NSMakeRange(startOfWordRange.location, endOfWordRange.location - startOfWordRange.location + 1);
    NSLog(@"word range:%@", NSStringFromRange(wordRange) );
    NSCharacterSet *underscoreCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"_"];
    NSRange underscoreRange = [self.currentTextTextView.text rangeOfCharacterFromSet:underscoreCharacterSet options:0 range:wordRange];
    NSRange targetRange;
    NSString *newString;
    NSString *textWithReplacementString;
    if (underscoreRange.location == NSNotFound) {
        
        // Show underscores from word through end.
        NSLog(@"hide text");
        
        targetRange = NSMakeRange(wordRange.location, self.currentTextTextView.text.length - wordRange.location);
        newString = [self.currentText.underscoreText substringWithRange:targetRange];
        textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:targetRange withString:newString];
        self.currentTextTextView.text = textWithReplacementString;
        
        // Set selected range to start of word.
        //self.currentTextTextView.selectedRange = NSMakeRange(wordRange.location, 0);
        
        // Keep track of range to show.
        NSInteger locationToShowThrough = wordRange.location - 2;
        if (locationToShowThrough < 0) {
            
            self.blanksModeLocationToShowThrough = NSNotFound;
        } else {
            
            self.blanksModeLocationToShowThrough = wordRange.location;
        }
    } else {
        
        // Show full text from start up through word.
        NSLog(@"reveal text");
        
        targetRange = NSMakeRange(0, endOfWordRange.location + 1);
        newString = [self.currentText.text substringWithRange:targetRange];
        textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:targetRange withString:newString];
        
        self.currentTextTextView.text = textWithReplacementString;
        
        // Set selected range to just after end of word.
        
        NSUInteger startOfNextWhitespace = endOfWordRange.location + 1;
        if (startOfNextWhitespace == self.currentTextTextView.text.length) {
            
            startOfNextWhitespace = startOfNextWhitespace - 1;
        }
        //self.currentTextTextView.selectedRange = NSMakeRange(startOfNextWhitespace, 0);
        
        // Keep track of range to show.
        self.blanksModeLocationToShowThrough = endOfWordRange.location;
    }
    */
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
		
		// Disable toolbar with this button.
		//self.bottomToolbar.userInteractionEnabled = NO;
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
	
    NSLog(@"RVC editTextViewControllerDidFinishEditing");
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
    
    // There is a custom double-tap gesture recognizer attached to the text view. Currently, it's the only gesture recognizer that has this class as its delegate. We want this recognizer to work with other double-tap recognizers inherent to the text view.
    // Actually now it's for two single-tap gesture recognizers.
    
    BOOL answer = NO;
    if ( [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
        
       //UITapGestureRecognizer *aTapGestureRecognizer = (UITapGestureRecognizer *)otherGestureRecognizer;
       // if (aTapGestureRecognizer.numberOfTapsRequired == 2) {
            
            answer = YES;
       // }
    } 
    return answer;
}

- (void)handleMarginDoubleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {
	
	// If not showing first letters, show them. Else, show full text.
	
	if (self.textToShowSegmentedControl.selectedSegmentIndex != self.firstLettersSegmentIndex) {
		
        self.textToShowSegmentedControl.selectedSegmentIndex = self.firstLettersSegmentIndex;
	} else {
		
		self.textToShowSegmentedControl.selectedSegmentIndex = self.fullTextSegmentIndex;
	}
    
    // In iOS 4.3, setting a UISegmentedControl's index programmatically will trigger the "value changed" event. In iOS 5, it doesn't. So we'll send it manually.
    double iOSVersion = [ [UIDevice currentDevice].systemVersion doubleValue];
    if (iOSVersion >= 5.0) {
        [self.textToShowSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)handleMarginSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {
        
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        // Hide/show textview.
        if (self.currentTextTextView.isHidden) {
            
            [self.currentTextTextView setHidden:NO];
        } else {
            
            [self.currentTextTextView setHidden:YES];
        }
        
        //[self showFirstLettersOnly];
    }
}

//?
- (void)handleSwipeLeftGesture:(UISwipeGestureRecognizer *)theSwipeGestureRecognizer {
    
    NSLog(@"swipe left detected");
    
    /*
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        // If our text view's selected range is not valid, then set the range to the end of the text.
        if (self.currentTextTextView.selectedRange.location >= [self.currentTextTextView.text length] ) {
            
            self.currentTextTextView.selectedRange = NSMakeRange(self.currentTextTextView.text.length - 1, 0);
        }
        
        NSLog(@"swipe left detected; selection:|%@|", NSStringFromRange(self.currentTextTextView.selectedRange) );
        
        [self hideFullTextForSelectedClause];
    }
     */
}

//?
- (void)handleSwipeRightGesture:(UISwipeGestureRecognizer *)theSwipeGestureRecognizer {
    
    NSLog(@"swipe right detected");
    
    /*
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        // If our text view's selected range is not valid, then set the range to the start of the text.
        if (self.currentTextTextView.selectedRange.location >= [self.currentTextTextView.text length] ) {
            
            self.currentTextTextView.selectedRange = NSMakeRange(0, 0);
        }
        
        NSLog(@"hSRG; selection:|%@|", NSStringFromRange(self.currentTextTextView.selectedRange) );
        
        [self showFullTextForSelectedClause];
    }*/
}

- (void)handleTextViewDoubleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {

    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        //self.textViewDoubleTapInFirstLetterModeDate = [NSDate date];
        if ( [self shouldShowFullTextForSelection] ) {
            
            [self showFullTextForSelection];
        } 
    }
}

// A single tap in the text view should reveal or hide words, depending on the context. What's important is to recognize the tap and determine where (the selection point). Since we're recognizing the selection point by allowing the normal single-tap in the text view, we need to allow simultaneous gesture recognition.
- (void)handleTextViewSingleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        NSLog(@"single tap in text view detected");
        self.textViewSingleTapInFirstLetterModeDate = [NSDate date];
        [self considerDoingSomethingAtSelectedRange];
        /*
        if ( [self shouldShowFullTextForSelection] ) {
            
            [self showFullTextForSelection];
        } */
    }
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.uniBlanksSegmentIndex) {
        
        NSLog(@"uniblanks tap detected");
        self.textViewSingleTapInFirstLetterModeDate = [NSDate date];
        [self considerDoingSomethingAtSelectedRange];
    }
}

// Show underscore text for the clause specified by the text view's selected range. The specification: If the range starts one character after the end of a clause, hide that clause. Otherwise, hide the clause that includes the start of the range.
- (void)hideFullTextForSelectedClause {
    
    // Plan: Get an index in the clause. Search backwards until end of previous clause (or start of text). Search forward to end of clause. Get underscore text for that range. Replace text in range. Set selection to start of range.
    
    NSCharacterSet *clauseEndsExceptCommaCharacterSet = [NSCharacterSet characterSetWithCharactersInString:clauseEndsExceptCommaString];
    
    NSUInteger indexInClause = self.currentTextTextView.selectedRange.location;
    if (indexInClause != 0) {
        
        // The character before the range start is in the desired clause, whether at the very end of the previous clause or in the middle of a clause.
        indexInClause = indexInClause - 1;
    }
    
    // Search backwards for end of previous clause. Don't include index in clause, because it might be a clause end.
    
    NSRange rangeToCheck = NSMakeRange(0, indexInClause);
    NSRange rangeOfEndOfClause = [self.currentTextTextView.text rangeOfCharacterFromSet:clauseEndsExceptCommaCharacterSet options:NSBackwardsSearch range:rangeToCheck];
    NSUInteger startOfClause;
    if (rangeOfEndOfClause.location == NSNotFound) {
        
        startOfClause = 0;
    } else {
        
        startOfClause = rangeOfEndOfClause.location + 1;
    }
    
    // Search forward for end of this clause.
    
    rangeToCheck = NSMakeRange(indexInClause, self.currentTextTextView.text.length - indexInClause);
    rangeOfEndOfClause = [self.currentTextTextView.text rangeOfCharacterFromSet:clauseEndsExceptCommaCharacterSet options:0 range:rangeToCheck];
    NSUInteger endOfClause;
    if (rangeOfEndOfClause.location == NSNotFound) {
        
        endOfClause = self.currentTextTextView.text.length - 1;
    } else {
        
        endOfClause = rangeOfEndOfClause.location;
    }
    
    NSRange rangeToHide = NSMakeRange(startOfClause, endOfClause - startOfClause + 1);
    NSString *underscoreTextString = [self.currentText.underscoreText substringWithRange:rangeToHide];
    NSString *textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:rangeToHide withString:underscoreTextString];
    
    self.currentTextTextView.text = textWithReplacementString;
    self.currentTextTextView.selectedRange = NSMakeRange(startOfClause, 0);
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
        // Custom initialization.
        self.blanksModeLocationToShowThrough = NSNotFound;
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
	self.topToolbar.userInteractionEnabled = YES;
}

// RecordingAndPlaybackControllerDelegate method. Since playback paused, show that in the button for the popover.
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

- (BOOL)shouldShowFullTextForSelection {
    
    // Check whether there was a double-tap in the text view in first-letter mode. Check whether the text view's selection changed. Check if both happened recently.
    
    BOOL answer = NO;
    /*
//    NSLog(@"RVC checking whether to show full text for selection...");
    if (self.textViewDoubleTapInFirstLetterModeDate != nil && self.textViewSelectionChangeDate != nil) {
        
//        NSLog(@"RVC dtap and selection-change both detected");

        if ( ( [self.textViewDoubleTapInFirstLetterModeDate timeIntervalSinceNow] > -0.1 ) && ( [self.textViewSelectionChangeDate timeIntervalSinceNow] > -0.1 ) ) {
            
//            NSLog(@"RVC dtap and selection-change both recent enough...");
                
            // A double-tap in whitespace may have the above be true, but the selected location will be NSNotFound. So check against that.
            if (self.currentTextTextView.selectedRange.location != NSNotFound) {
                
//                NSLog(@"RVC selection is valid...");
                answer = YES;
            }
        }
    }*/
    return answer;
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

// Show the full text for a specific clause: The clause that includes the start of the text view's selected range.
- (void)showFullTextForSelectedClause {
    
    // Plan: Get an index in the clause. Search forward to the end of the clause (or end of text). Search backwards until the end of the previous clause (or start of text). Get full text for that range. Replace text in range. Set selection to just after the range.
    
    NSCharacterSet *clauseEndsExceptCommaCharacterSet = [NSCharacterSet characterSetWithCharactersInString:clauseEndsExceptCommaString];
    
    NSUInteger indexInClause = self.currentTextTextView.selectedRange.location;
    
    // Search forward for the end of this clause.
    
    NSRange rangeToCheck = NSMakeRange(indexInClause, self.currentTextTextView.text.length - indexInClause);
    NSRange rangeOfEndOfClause = [self.currentTextTextView.text rangeOfCharacterFromSet:clauseEndsExceptCommaCharacterSet options:0 range:rangeToCheck];
    NSUInteger endOfClause;
    if (rangeOfEndOfClause.location == NSNotFound) {
        
        endOfClause = self.currentTextTextView.text.length - 1;
    } else {
        
        endOfClause = rangeOfEndOfClause.location;
    }
    
    // Search backwards for end of previous clause. Don't include index in clause, because it might be a clause end.
    
    rangeToCheck = NSMakeRange(0, indexInClause);
    rangeOfEndOfClause = [self.currentTextTextView.text rangeOfCharacterFromSet:clauseEndsExceptCommaCharacterSet options:NSBackwardsSearch range:rangeToCheck];
    NSUInteger startOfClause;
    if (rangeOfEndOfClause.location == NSNotFound) {
        
        startOfClause = 0;
    } else {
        
        startOfClause = rangeOfEndOfClause.location + 1;
    }
    
    NSRange rangeToReveal = NSMakeRange(startOfClause, endOfClause - startOfClause + 1);
    NSString *newString = [self.currentText.text substringWithRange:rangeToReveal];
    NSString *textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:rangeToReveal withString:newString];
    
    self.currentTextTextView.text = textWithReplacementString;
    NSUInteger startOfNextClause = endOfClause + 1;
    if (startOfNextClause == self.currentTextTextView.text.length) {
        
        startOfNextClause = startOfNextClause - 1;
    }
    self.currentTextTextView.selectedRange = NSMakeRange(startOfNextClause, 0);
}

- (void)showFullTextForSelection {
    
    // In iOS 4.3, when a word is double-tapped, the edit menu appears briefly. Stop that from occurring.
    [UIMenuController sharedMenuController].menuVisible = NO;
    
    // Check char at start of range (even if length 0). If underscore, then extend left side until non-underscore.
    
    NSUInteger startLocation;
    NSUInteger firstSelectedCharacterIndex = self.currentTextTextView.selectedRange.location;
    unichar firstSelectedCharacter = [self.currentTextTextView.text characterAtIndex:firstSelectedCharacterIndex];
    NSCharacterSet *nonUnderscoreCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"_"] invertedSet];
    if (firstSelectedCharacter == '_' && firstSelectedCharacterIndex != 0) {
        
        // Check characters before the start of the range.
        NSRange rangeToCheck = NSMakeRange(0, firstSelectedCharacterIndex);
        
        NSRange rangeOfFirstNonUnderscore = [self.currentTextTextView.text rangeOfCharacterFromSet:nonUnderscoreCharacterSet options:NSBackwardsSearch range:rangeToCheck];
        startLocation = rangeOfFirstNonUnderscore.location;
    } else {
        startLocation = firstSelectedCharacterIndex;
    }
    
    // Check char just after end of range. If underscore, then extend right side until non-underscore.
    
    NSUInteger endLocation;
    NSUInteger nextCharacterIndex;
    if (self.currentTextTextView.selectedRange.length == 0) {
        
        nextCharacterIndex = firstSelectedCharacterIndex + 1;
    } else {
        
        nextCharacterIndex = NSMaxRange(self.currentTextTextView.selectedRange);
    }
    if (nextCharacterIndex < [self.currentTextTextView.text length] ) {
        
        unichar nextCharacter = [self.currentTextTextView.text characterAtIndex:nextCharacterIndex];
        if (nextCharacter == '_') {
            
            NSRange rangeToCheck = NSMakeRange(nextCharacterIndex, [self.currentTextTextView.text length] - nextCharacterIndex);
            NSRange rangeOfFirstNonUnderscore = [self.currentTextTextView.text rangeOfCharacterFromSet:nonUnderscoreCharacterSet options:0 range:rangeToCheck];
            endLocation = rangeOfFirstNonUnderscore.location - 1;
        } else {
            
            endLocation = nextCharacterIndex - 1;
        }
    } else {
        
        endLocation = nextCharacterIndex - 1;
    }
    
    if (endLocation >= startLocation) {
        
        // Replace text in range with full text.
    
        NSRange rangeToShowAsFullText = NSMakeRange(startLocation, endLocation - startLocation + 1);
        NSString *fullTextString = [self.currentText.text substringWithRange:rangeToShowAsFullText];
        //NSLog(@"RVC tVDCS. Word to show:||%@||", fullTextString);
        NSString *textWithReplacementString = [self.currentTextTextView.text stringByReplacingCharactersInRange:rangeToShowAsFullText withString:fullTextString];
        
        self.currentTextTextView.text = textWithReplacementString;
    }
}

- (IBAction)showRecordingPopover:(id)sender {
    
    // Careful here. Checking that popover's view controller is a nav controller. If we have multiple popovers like this, we'll need another way to discriminate.
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

- (void)showUnderscoresOnly {
	
    if (self.previousBlanksModeString != nil) {
        
        self.currentTextTextView.text = self.previousBlanksModeString;
    } else {
        
        self.currentTextTextView.text = self.currentText.underscoreText;
    }
    
    /*
    // Show words that were visible last time.
    if (self.blanksModeLocationToShowThrough != NSNotFound) {
        
        self.currentTextTextView.selectedRange = NSMakeRange(self.blanksModeLocationToShowThrough, 0);
        [self doSomethingAtSelectedRange];
    }*/
}

- (void)showUniBlanks {
    
    if (self.previousUniBlankModeString != nil) {
        
        self.currentTextTextView.text = self.previousUniBlankModeString;
    } else {
        
        self.currentTextTextView.text = [self.currentText getUniBlankText];
    }
}

- (void)textsTableViewControllerDidSelectText:(TextsTableViewController *)sender {
	
	[self.popoverController dismissPopoverAnimated:YES];
	
	// Dismissing popover programmatically doesn't call this delegate method. But we do cleanup there, so we need to call it.
	[self popoverControllerDidDismissPopover:nil];
	
    //self.blanksModeLocationToShowThrough = NSNotFound;
    self.previousBlanksModeString = nil;
    self.previousUniBlankModeString = nil;
	self.currentText = sender.currentText;
}

- (void)textViewDidChangeSelection:(UITextView *)theTextView {
	
    // In first-letter mode, the text view is editable to allow a single tap to set the selection range. But we don't want the keyboard to show up, so we'll always resign the first responder.
    if ( ( (self.textToShowSegmentedControl.selectedSegmentIndex == firstLettersSegmentIndex) || (self.textToShowSegmentedControl.selectedSegmentIndex == uniBlanksSegmentIndex) ) && self.currentTextTextView.isFirstResponder) {
        
        [self.currentTextTextView resignFirstResponder];
    }
    
    // Sometimes the selected range will be beyond the end of the text. In that case, do nothing.
    if (self.currentTextTextView.selectedRange.location >= self.currentTextTextView.text.length) {
        
        return;
    }
    
    /*
    if ( [self shouldShowFullTextForSelection] ) {
        
        [self showFullTextForSelection];
    }*/
    // need to make sure this works regardless of order of the selection change and the custom single-tap; tricky because of checking whether selection is/was valid
    // the selection change should control one flag, the tap a second flag; both will call a method which checks both flags and the dates of both flags
    // scenarios: tap first, selection second
    // selection first, tap second
    // change textViewSelectionIsValid to take in the locations and dates, so it can't be called elsewhere?
    if ([self textViewSelectedRangeIsCorrect]) {
        
        self.textViewSelectedRangeIsCorrectDate = [NSDate date];
        [self considerDoingSomethingAtSelectedRange];
    } else {
        
        self.textViewSelectedRangeIsCorrectDate = nil;
    }
    self.previousSelectedRangeLocation = self.currentTextTextView.selectedRange.location;
    self.previousSelectedRangeDate = [NSDate date];
}

- (BOOL)textViewSelectedRangeIsCorrect {
    
    // When user single-taps in the text view, textViewDidChangeSelection is called twice. The first time, the selected range is the text length (in iOS 4.3) or the previous range (in iOS 5.0). The second time, the selected range is correct (i.e., where the tap was). So we want to ignore the first textViewDidChangeSelection. (If user double-taps, then textViewDidChangeSelection is called four times, with the correct range the last three times.)

    // Assume selected ranges outside the text range were already ignored. 
    // If the user taps once and later taps elsewhere, then the previous range will be detected once and the new range will be detected immediately after.
    // If the user taps once and later taps in exactly the same place, then the previous range will be detected twice, with the second time immediately after the first. 
    // So, we'll check if the current range is identical to the previous range. If so, the current range is incorrect. The exception is if the current range change happened immediately after the previous range change (e.g., < 0.1 seconds).
    
    BOOL answer = YES;
    if (self.currentTextTextView.selectedRange.location == self.previousSelectedRangeLocation) {
        
        answer = NO;
        NSTimeInterval timeSincePreviousSelectedRange = [ [NSDate date] timeIntervalSinceDate:self.previousSelectedRangeDate];
        //NSLog(@"time interval:%f", timeSincePreviousSelectedRange);
        if (timeSincePreviousSelectedRange < 0.1) {
            
            NSLog(@"dates were very close");
            answer = YES;
        }
    }
    return answer;
}

- (void)updateTitleAndTextShowing {
	
	self.titleLabel.text = self.currentText.title;
    self.previousBlanksModeString = nil;
    self.previousUniBlankModeString = nil;
	if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        [self showUnderscoresOnly];
	} else if (self.textToShowSegmentedControl.selectedSegmentIndex == self.uniBlanksSegmentIndex) {
        
        [self showUniBlanks];
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
		self.firstLettersSegmentIndex = 1;
        self.nothingSegmentIndex = 2;
        self.uniBlanksSegmentIndex = 3;
		[self.textToShowSegmentedControl setTitle:fullTextModeTitleString forSegmentAtIndex:self.fullTextSegmentIndex];
		[self.textToShowSegmentedControl setTitle:blanksTextModeTitleString forSegmentAtIndex:self.firstLettersSegmentIndex];
        [self.textToShowSegmentedControl setTitle:nothingTextModeTitleString forSegmentAtIndex:self.nothingSegmentIndex];
        [self.textToShowSegmentedControl setTitle:uniBlanksTextModeTitleString forSegmentAtIndex:self.uniBlanksSegmentIndex];
		
		// Add overlay view on top of all views.
		CGRect windowMinusBarsFrame = CGRectMake(0, self.currentTextTextView.frame.origin.y, self.view.frame.size.width, self.currentTextTextView.frame.size.height);
		OverlayView *anOverlayView = [[OverlayView alloc] initWithFrame:windowMinusBarsFrame];
		anOverlayView.textViewToIgnore = self.currentTextTextView;
		[self.view addSubview:anOverlayView];
        
        /*
        // Add gesture recognizer for single taps in the text margins.
		UITapGestureRecognizer *aSingleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMarginSingleTapGesture:)];
		aSingleTapGestureRecognizer.numberOfTapsRequired = 1;
        [anOverlayView addGestureRecognizer:aSingleTapGestureRecognizer];
		[aSingleTapGestureRecognizer release];
		[anOverlayView release];
         */
        
        /*
        // Add gesture recognizer for a swipe right.
        UISwipeGestureRecognizer *aSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightGesture:) ];
        aSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:aSwipeGestureRecognizer];
        [aSwipeGestureRecognizer release];
        
        // Add gesture recognizer for a swipe left.
        aSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftGesture:) ];
        aSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:aSwipeGestureRecognizer];
        [aSwipeGestureRecognizer release];
         */
		
		// Align text view so it doesn't appear to shift later.
		[self maintainRelativeWidthOfTextView:self.currentTextTextView];
		
		// Set initial text.
		self.currentText = [self introText];
		
		// Set text view's delegate.
		self.currentTextTextView.delegate = self;
        
        // Add gesture recognizer: single tap in text view.
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


