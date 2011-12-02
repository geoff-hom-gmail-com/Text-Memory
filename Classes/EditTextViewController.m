    //
//  EditTextViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditTextViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"
#import "Text.h"
#import "TextMemoryAppDelegate.h"

// Private category for private methods.
@interface EditTextViewController ()

// The current font.
@property (nonatomic, retain) UIFont *currentFont;

// Frame for the text view when no keyboard is showing.
@property (nonatomic) CGRect defaultTextViewFrame;

// The alert view for editing the title.
@property (nonatomic, retain) UIAlertView *titleAlertView;

// The text field for editing the title. Shown in an alert view.
@property (nonatomic, retain) UITextField *titleTextField;

// Remove/pop this view controller, but instead of the navigation controller's transition, do a fade.
- (void)fadeAway;

// Restore the size of the text view (fill self's view). Animate the resize so that it's in sync with the disappearance of the keyboard.
- (void)keyboardWillHide:(NSNotification *)notification;

// Reduce the size of the text view so that it's not obscured by the keyboard. Animate the resize so that it's in sync with the appearance of the keyboard.
- (void)keyboardWillShow:(NSNotification *)notification;

// Given a text view, set its width to span the test string. Also, keep the view centered. (Also in RootViewController. Could make utility.)
- (void)maintainRelativeWidthOfTextView:(UITextView *)theTextView;

@end


@implementation EditTextViewController

@synthesize currentFont, defaultTextViewFrame, titleAlertView, titleTextField;
@synthesize contentOffset, currentText, currentTextTextView, delegate, titleBarButtonItem;

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 1) {
		
		// Save new title.
		self.currentText.title = self.titleTextField.text;
		TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
		[aTextMemoryAppDelegate saveContext];
		self.titleBarButtonItem.title = [NSString stringWithFormat:@"Editing \"%@\"", self.currentText.title];
	}
}

- (IBAction)cancelEditing:(id)sender {
	
	// Notify the delegate.
	[self.delegate editTextViewControllerDidFinishEditing:self];
	
	[self fadeAway];
}

- (void)dealloc {
	
	[currentFont release];
	[titleAlertView release];
	[titleTextField release];
	
	[currentText release];
	[currentTextTextView release];
	[titleBarButtonItem release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)fadeAway {
	
	CATransition *aTransition = [CATransition animation];
	aTransition.duration = fadeTransitionDuration;
	[self.navigationController.view.layer addAnimation:aTransition forKey:nil];
	[self.navigationController popViewControllerAnimated:NO];
}

- (id)initWithText:(Text *)theText contentOffset:(CGPoint)theContentOffset font:(UIFont *)theFont {
	
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		
        self.currentText = theText;
		self.contentOffset = theContentOffset;
		self.currentFont = theFont;
    }
    return self;
}

- (void)keyboardWillHide:(NSNotification *)notification {
	
    NSDictionary* userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.currentTextTextView.frame = self.defaultTextViewFrame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = self.currentTextTextView.frame;
    newTextViewFrame.size.height = keyboardTop - newTextViewFrame.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
	self.defaultTextViewFrame = self.currentTextTextView.frame;
    self.currentTextTextView.frame = newTextViewFrame;
	
    [UIView commitAnimations];
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

- (IBAction)renameTitle:(id)sender {
	
	// In iOS 5.0, UIAlertViewStylePlainTextInput should work. Until then, we'll add a text field to the alert view. The alert's message provides space for the text view. 
	UIAlertView *anAlertView = [[UIAlertView alloc] initWithTitle:@"Rename Title" message:@"\n " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	UITextField *aTextField = [[UITextField alloc] initWithFrame:CGRectMake(17.0, 57.0, 250.0, 27.0)];
	aTextField.borderStyle = UITextBorderStyleRoundedRect;
	aTextField.delegate = self;
	aTextField.returnKeyType = UIReturnKeyDone;
	aTextField.text = self.currentText.title;
	[anAlertView addSubview:aTextField];
	self.titleTextField = aTextField;
	[aTextField release];
	[anAlertView show];
	self.titleAlertView = anAlertView;
	[anAlertView release];
	
	// Show cursor and keyboard. We could use [aTextField becomeFirstResponder], but there's a significant animation delay. The line below results in no delay.
	[aTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0];
}

- (IBAction)saveEditing:(id)sender {
	
	// Save current Text.
	self.currentText.text = self.currentTextTextView.text;
	self.contentOffset = self.currentTextTextView.contentOffset;
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	[aTextMemoryAppDelegate saveContext];
	
	// Notify the delegate.
	[self.delegate editTextViewControllerDidFinishEditing:self];
	
	[self fadeAway];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[self.titleAlertView dismissWithClickedButtonIndex:1 animated:YES];
	return NO;
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
	// Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	self.titleBarButtonItem.title = [NSString stringWithFormat:@"Editing \"%@\"", self.currentText.title];
	
	// Set font.
	self.currentTextTextView.font = self.currentFont;
	[self maintainRelativeWidthOfTextView:self.currentTextTextView];
	
	self.currentTextTextView.text = self.currentText.text;
	self.currentTextTextView.contentOffset = self.contentOffset;
}

- (void)viewDidUnload {
	
    [super viewDidUnload];
    
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.titleAlertView = nil;
	self.titleTextField = nil;
	self.currentTextTextView = nil;
	self.titleBarButtonItem = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

@end
