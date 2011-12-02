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
#import "OverlayView.h"
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

// Title for segmented control segment for showing first letters.
NSString *firstLetterTextModeTitleString = @"First Letters";

// Title for segmented control segment for showing full text.
NSString *fullTextModeTitleString = @"Full Text";

NSString *testWidthString = @"_abcdefghijklmnopqrstuvwxyzabcdefghijklm_";

// Private category for private methods.
@interface RootViewController ()

// Segment in segmented control for switching to first-letter mode.
@property (nonatomic) NSUInteger firstLettersSegmentIndex;

// Segment in segmented control for switching to full-text mode.
@property (nonatomic) NSUInteger fullTextSegmentIndex;

// Once we create this, we'll keep it in memory and just reuse it.
@property (nonatomic, retain) UIPopoverController *popoverController;

// Date when the text view was double-tapped while in first-letter mode.
@property (nonatomic, retain) NSDate *textViewDoubleTapInFirstLetterModeDate;

// Date when the text view's selection changed.
@property (nonatomic, retain) NSDate *textViewSelectionChangeDate;

// Add a new text and show it.
- (void)addANewText;

// Start key-value observing.
- (void)addObservers;

// Delete the current text.
- (void)deleteCurrentText;

// Go to editing view for the current text.
- (void)editCurrentText;

- (void)hideFullTextForSelectedClause;

// Given a text view, set its width to span the test string. Also, keep the view centered.
- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView;

// Stop key-value observing.
- (void)removeObservers;

// Return whether to show the full text for the text view's selection. Should return YES if the user double-tapped on a word while in first-letter mode.
- (BOOL)shouldShowFullTextForSelection;

// Show only the first letter of each word (plus punctuation).
- (void)showFirstLettersOnly;

// Show the entire text (vs. only first letters).
- (void)showFullText;

- (void)showFullTextForSelectedClause;

// Show the entire text for the text view's current selection (in first-letter mode), expanding to at least a word.
- (void)showFullTextForSelection;

// Make sure the correct title and text is showing. (And that the text's mode is correct.)
- (void)updateTitleAndTextShowing;

@end

@implementation RootViewController

@synthesize addTextBarButtonItem, bottomToolbar, currentText, currentTextTextView, editTextBarButtonItem, textToShowSegmentedControl, titleLabel, topToolbar, trashBarButtonItem;
@synthesize firstLettersSegmentIndex, fullTextSegmentIndex, popoverController, textViewDoubleTapInFirstLetterModeDate, textViewSelectionChangeDate;

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
	self.topToolbar.userInteractionEnabled = YES;
	self.bottomToolbar.userInteractionEnabled = YES;
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

	if (theSegmentedControl.selectedSegmentIndex == self.fullTextSegmentIndex) {
		
		[self showFullText];
        self.currentTextTextView.editable = NO;
	} else if (theSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
		
		[self showFirstLettersOnly];
        self.currentTextTextView.editable = YES;
	}
}

- (IBAction)confirmAddText:(id)sender {
	
	// Ask user to confirm/choose via an action sheet.
	UIActionSheet *anActionSheet;
	anActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:addTextTitleString, nil];
	[anActionSheet showFromBarButtonItem:self.addTextBarButtonItem animated:NO];
	[anActionSheet release];
	
	// Disable toolbar with this button.
	self.topToolbar.userInteractionEnabled = NO;
}

- (IBAction)confirmDeleteCurrentText:(id)sender {
	
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
	[anActionSheet release];
	
	// Disable toolbar with this button.
	self.bottomToolbar.userInteractionEnabled = NO;
}

- (IBAction)confirmEditCurrentText:(id)sender {
	
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
	[anActionSheet release];
	
	// Disable toolbar with this button.
	self.topToolbar.userInteractionEnabled = NO;
}

- (void)dealloc {
	
	[self removeObservers];
	
	self.popoverController.delegate = nil;
	[popoverController release];
	[textViewDoubleTapInFirstLetterModeDate release];
    [textViewSelectionChangeDate release];
    
	[introText_ release];
    
	[addTextBarButtonItem release];
	[bottomToolbar release];
	[currentText release];
	self.currentTextTextView.delegate = nil;
	[currentTextTextView release];
	[editTextBarButtonItem release];
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
		self.bottomToolbar.userInteractionEnabled = NO;
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
    
    // There is a custom double-tap gesture recognizer attached to the text view. Currently, it's the only gesture recognizer that has this class as its delegate. We want this recognizer to work with other double-tap recognizers inherent to the text view.
    
    BOOL answer = NO;
    if ( [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] ) {
        
        UITapGestureRecognizer *aTapGestureRecognizer = (UITapGestureRecognizer *)otherGestureRecognizer;
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
        
        [self showFirstLettersOnly];
    }
}

//?
- (void)handleSwipeLeftGesture:(UISwipeGestureRecognizer *)theSwipeGestureRecognizer {
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        // If our text view's selected range is not valid, then set the range to the end of the text.
        if (self.currentTextTextView.selectedRange.location >= [self.currentTextTextView.text length] ) {
            
            self.currentTextTextView.selectedRange = NSMakeRange(self.currentTextTextView.text.length - 1, 0);
        }
        
        NSLog(@"swipe left detected; selection:|%@|", NSStringFromRange(self.currentTextTextView.selectedRange) );
        
        [self hideFullTextForSelectedClause];
    }
}

//?
- (void)handleSwipeRightGesture:(UISwipeGestureRecognizer *)theSwipeGestureRecognizer {
    
    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        // If our text view's selected range is not valid, then set the range to the start of the text.
        if (self.currentTextTextView.selectedRange.location >= [self.currentTextTextView.text length] ) {
            
            self.currentTextTextView.selectedRange = NSMakeRange(0, 0);
        }
        
        NSLog(@"hSRG; selection:|%@|", NSStringFromRange(self.currentTextTextView.selectedRange) );
        
        [self showFullTextForSelectedClause];
    }
}

- (void)handleTextViewDoubleTapGesture:(UITapGestureRecognizer *)theTapGestureRecognizer {

    if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
        
        self.textViewDoubleTapInFirstLetterModeDate = [NSDate date];
        if ( [self shouldShowFullTextForSelection] ) {
            
            [self showFullTextForSelection];
        } 
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

- (void)removeObservers {
	
	[self removeObserver:self forKeyPath:@"currentText"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (BOOL)shouldShowFullTextForSelection {
    
    // Check whether there was a double-tap in the text view in first-letter mode. Check whether the text view's selection changed. Check if both happened recently.
    
    BOOL answer = NO;
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
    }
    return answer;
}

- (void)showFirstLettersOnly {
	
	//self.currentTextTextView.text = self.currentText.firstLetterText;
    self.currentTextTextView.text = self.currentText.underscoreText;
}

- (IBAction)showFontSizePopover:(id)sender {
    
	if (!self.popoverController.popoverVisible) {
		
		// Create the view controller for the popover.
		FontSizeViewController *aFontSizeViewController = [[FontSizeViewController alloc] init];
		aFontSizeViewController.delegate = self;
		aFontSizeViewController.currentFontSize = self.currentTextTextView.font.pointSize;
		UIViewController *aViewController = aFontSizeViewController;
		
		// Create the popover controller, if necessary.
		if (!self.popoverController) {
			
			UIPopoverController *aPopoverController = [[UIPopoverController alloc] initWithContentViewController:aViewController];
			self.popoverController = aPopoverController;
			[aPopoverController release];
		} else {
			self.popoverController.contentViewController = aViewController;
		}
		[aViewController release];
		
		// Resize popover.
		self.popoverController.popoverContentSize = self.popoverController.contentViewController.contentSizeForViewInPopover;
		
		// Present popover.
		self.popoverController.delegate = self;
		[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		
		// Disable toolbar (until popover dismissed).
		self.topToolbar.userInteractionEnabled = NO;
	}	
}

//put in header; alphabetize
- (void)showUnderscoresOnly {
	
	self.currentTextTextView.text = self.currentText.underscoreText;
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

- (IBAction)showTextsPopover:(id)sender {
	
	if (!self.popoverController.popoverVisible) {
			
		// Create the view controller for the popover.
		TextsTableViewController *aTextsTableViewController = [[TextsTableViewController alloc] init];
		aTextsTableViewController.delegate = self;
		aTextsTableViewController.currentText = self.currentText;
		UIViewController *aViewController = aTextsTableViewController;
		
		// Create the popover controller, if necessary.
		if (!self.popoverController) {
			
			UIPopoverController *aPopoverController = [[UIPopoverController alloc] initWithContentViewController:aViewController];
			self.popoverController = aPopoverController;
			[aPopoverController release];
		} else {
			self.popoverController.contentViewController = aViewController;
			
		}
		[aViewController release];
		
		// Resize popover.
		self.popoverController.popoverContentSize = self.popoverController.contentViewController.contentSizeForViewInPopover;
		
		// Present popover.
		self.popoverController.delegate = self;
		[self.popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		
		// Disable toolbar (until popover dismissed).
		self.topToolbar.userInteractionEnabled = NO;
	}	
}

- (void)textsTableViewControllerDidSelectText:(TextsTableViewController *)sender {
	
	[self.popoverController dismissPopoverAnimated:YES];
	
	// Dismissing popover programmatically doesn't call this delegate method. But we do cleanup there, so we need to call it.
	[self popoverControllerDidDismissPopover:nil];
	
	self.currentText = sender.currentText;
}

- (void)textViewDidChangeSelection:(UITextView *)theTextView {
	
    NSLog(@"RVC selection changed to:||%@||", NSStringFromRange(theTextView.selectedRange) );
    
    // Sometimes the selected range will be beyond the end of the text. In that case, hide the edit menu and do nothing.
    
    if (self.currentTextTextView.selectedRange.location >= [self.currentTextTextView.text length] ) {
        
        // The edit menu will still appear sometimes. For example, if the user double-taps in certain non-word areas (e.g., right before a word? in whitespace?). It doesn't happen every time the range equals the length, but when it does happen, the range equals the length. However, logging here says the menu isn't visible, and setting it not visible here doesn't help. In this case, the edit menu must be triggered downstream, elsewhere. 
        // Update: Resigning first responder seems to prevent the edit menu from appearing.
        
        //[[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
        
        if (self.currentTextTextView.isFirstResponder) {
            
            [self.currentTextTextView resignFirstResponder];
        }
        
        return;
    }
    
    //testing; if in fl mode, always resign first responder to avoid keyboard showing up?
    if ( (self.textToShowSegmentedControl.selectedSegmentIndex == firstLettersSegmentIndex) && self.currentTextTextView.isFirstResponder) {
        
        [self.currentTextTextView resignFirstResponder];
    }
    
    self.textViewSelectionChangeDate = [NSDate date];
    if ( [self shouldShowFullTextForSelection] ) {
        
        [self showFullTextForSelection];
    }
}

- (void)updateTitleAndTextShowing {
	
	self.titleLabel.text = self.currentText.title;
	if (self.textToShowSegmentedControl.selectedSegmentIndex == self.firstLettersSegmentIndex) {
		[self showFirstLettersOnly];
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
	
		// Start KVO. 
		[self addObservers];
		
		// Set up segmented control for showing first letters.
		self.fullTextSegmentIndex = 0;
		self.firstLettersSegmentIndex = 1;
		[self.textToShowSegmentedControl setTitle:fullTextModeTitleString forSegmentAtIndex:self.fullTextSegmentIndex];
		[self.textToShowSegmentedControl setTitle:firstLetterTextModeTitleString forSegmentAtIndex:self.firstLettersSegmentIndex];
		
		// Add overlay view on top of all views.
		CGRect windowMinusBarsFrame = CGRectMake(0, self.currentTextTextView.frame.origin.y, self.view.frame.size.width, self.currentTextTextView.frame.size.height);
		OverlayView *anOverlayView = [[OverlayView alloc] initWithFrame:windowMinusBarsFrame];
		anOverlayView.textViewToIgnore = self.currentTextTextView;
		[self.view addSubview:anOverlayView];
        
		// Add gesture recognizer for double taps in the text margins.
		UITapGestureRecognizer *aDoubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMarginDoubleTapGesture:)];
		aDoubleTapGestureRecognizer.numberOfTapsRequired = 2;
		[anOverlayView addGestureRecognizer:aDoubleTapGestureRecognizer];
		[aDoubleTapGestureRecognizer release];
        
        // Add gesture recognizer for single taps in the text margins.
		UITapGestureRecognizer *aSingleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMarginSingleTapGesture:)];
		aSingleTapGestureRecognizer.numberOfTapsRequired = 1;
        [anOverlayView addGestureRecognizer:aSingleTapGestureRecognizer];
		[aSingleTapGestureRecognizer release];
		[anOverlayView release];
        
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
		
		// Align text view so it doesn't appear to shift later.
		[self maintainRelativeWidthOfTextView:self.currentTextTextView];
		
		// Set initial text.
		self.currentText = [self introText];
		
		// Set text view's delegate.
		self.currentTextTextView.delegate = self;
        
        // Add gesture recognizer for double taps in the text view.
        aDoubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextViewDoubleTapGesture:)];
        aDoubleTapGestureRecognizer.numberOfTapsRequired = 2;
        aDoubleTapGestureRecognizer.delegate = self;
		[self.currentTextTextView addGestureRecognizer:aDoubleTapGestureRecognizer];
        [aDoubleTapGestureRecognizer release];        
	}
}

- (void)viewDidUnload {
	
    [super viewDidUnload];
    
	[self removeObservers];
	
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
    self.popoverController.delegate = nil;
	self.popoverController = nil;
    
	self.addTextBarButtonItem = nil;
	self.bottomToolbar = nil;
	self.currentTextTextView.delegate = nil;
	self.currentTextTextView = nil;
	self.editTextBarButtonItem = nil;
	self.textToShowSegmentedControl = nil;
	self.titleLabel = nil;
	self.topToolbar = nil;
	self.trashBarButtonItem = nil;
}

@end


