    //
//  FontSizeViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FontSizeViewController.h"

// Minimum font size to display.
CGFloat minimumFontSize = 13.0;

// Maximum font size to display
CGFloat maximumFontSize = 29.0;

@implementation FontSizeViewController

@synthesize currentFontSize, decreaseFontSizeButton, delegate, increaseFontSizeButton;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

- (void)viewDidLoad {

    [super viewDidLoad];
	
	if (self.currentFontSize <= minimumFontSize) {
		self.decreaseFontSizeButton.enabled = NO;
	}
	if (self.currentFontSize >= maximumFontSize) {
		self.increaseFontSizeButton.enabled = NO;
	}

	self.contentSizeForViewInPopover = self.view.frame.size;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	
    [super viewDidUnload];
    
	// Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.decreaseFontSizeButton = nil;
	self.increaseFontSizeButton = nil;
}


- (void)dealloc {
	
	[decreaseFontSizeButton release];
	[increaseFontSizeButton release];
	
    [super dealloc];
}

- (IBAction)decreaseFontSize:(id)sender {
	
	self.currentFontSize -= 2.0;
	if (self.currentFontSize <= minimumFontSize) {
		self.currentFontSize = minimumFontSize;
		self.decreaseFontSizeButton.enabled = NO;
	}
	if (self.currentFontSize < maximumFontSize) {
		self.increaseFontSizeButton.enabled = YES;
	}
	[self.delegate fontSizeViewControllerDidChangeFontSize:self];
}

- (IBAction)increaseFontSize:(id)sender {
	
	self.currentFontSize += 2.0;
	if (self.currentFontSize >= maximumFontSize) {
		self.currentFontSize = maximumFontSize;
		self.increaseFontSizeButton.enabled = NO;
	}
	if (self.currentFontSize > minimumFontSize) {
		self.decreaseFontSizeButton.enabled = YES;
	}
	[self.delegate fontSizeViewControllerDidChangeFontSize:self];
}

@end
