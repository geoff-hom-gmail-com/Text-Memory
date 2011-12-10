//
//  RecordingAndPlaybackController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordingAndPlaybackController : NSObject

// Navigation controller for switching between subviews.
@property (nonatomic, retain) UINavigationController *navigationController;

// A segmented control for whether to record voice or play it back.
//@property (nonatomic, retain) IBOutlet UISegmentedControl *recordOrPlaySegmentedControl;

// Show controls according to the segment selected: Recording or playback.
- (IBAction)changeMode:(UISegmentedControl *)theSegmentedControl;

@end
