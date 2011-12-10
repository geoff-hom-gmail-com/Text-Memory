//
//  RecordingAndPlaybackController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RecordingAndPlaybackController.h"
#import "RecordingViewController.h"

// Private category for private methods.
@interface RecordingViewController ()

// Show controls for playing back the user's voice.
//- (void)showPlaybackControls;

// Show controls for recording the user's voice.
//- (void)showRecordingControls;

@end

@implementation RecordingAndPlaybackController

@synthesize navigationController;

- (IBAction)changeMode:(UISegmentedControl *)theSegmentedControl {
    
    // 0 is "Record." 1 is "Play."
    if (theSegmentedControl.selectedSegmentIndex == 0) {
		
		//[self showRecordingControls];
	} else {
		
		//[self showPlaybackControls];
	}
}

// Override of NSObject method. Create the navigation controller and root view controller.
- (id)init {
    
    self = [super init];
    if (self != nil) {
        
        RecordingViewController *aRecordingViewController = [[RecordingViewController alloc] init];
        UISegmentedControl *aSegmentedControl = [ [UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Record", @"Playtest", nil] ];
        aSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        // add target
        aRecordingViewController.navigationItem.titleView = aSegmentedControl;
        [aSegmentedControl release];
        UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:aRecordingViewController];
        [aRecordingViewController release];
        self.navigationController = aNavigationController;
        [aNavigationController release];
    }
    return self;
}

- (void)dealloc {
    
    [navigationController release];
    
    [super dealloc];
}

@end
