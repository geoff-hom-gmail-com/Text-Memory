//
//  RecordingAndPlaybackController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlaybackViewController.h"
#import "RecordingViewController.h"

@class RecordingAndPlaybackController;

@protocol RecordingAndPlaybackControllerDelegate

// Sent after recording has paused.
- (void)recordingAndPlaybackControllerDidPauseRecording:(RecordingAndPlaybackController *)sender;

// Sent after playback has started.
- (void)recordingAndPlaybackControllerDidStartPlaying:(RecordingAndPlaybackController *)sender;

// Sent after recording has started.
- (void)recordingAndPlaybackControllerDidStartRecording:(RecordingAndPlaybackController *)sender;

// Sent after playback has stopped.
- (void)recordingAndPlaybackControllerDidStopPlaying:(RecordingAndPlaybackController *)sender;

// Sent after recording has stopped.
- (void)recordingAndPlaybackControllerDidStopRecording:(RecordingAndPlaybackController *)sender;

@end

@interface RecordingAndPlaybackController : NSObject <PlaybackViewControllerDelegate, RecordingViewControllerDelegate>

@property (nonatomic, assign) id <RecordingAndPlaybackControllerDelegate> delegate;

// Navigation controller for switching between subviews.
@property (nonatomic, retain) UINavigationController *navigationController;

// Override of NSObject method. Create the navigation controller and the segmented control.
- (id)init;

// PlaybackViewControllerDelegate method. Since playback started, notify our delegate.
- (void)playbackViewControllerDidStartPlaying:(PlaybackViewController *)playbackViewController;

// PlaybackViewControllerDelegate method. Since playback stopped, notify our delegate.
- (void)playbackViewControllerDidStopPlaying:(PlaybackViewController *)playbackViewController;

// RecordingViewControllerDelegate method. Since recording paused, notify our delegate.
- (void)recordingViewControllerDidPauseRecording:(RecordingViewController *)recordingViewController;

// RecordingViewControllerDelegate method. Since recording started, notify our delegate.
- (void)recordingViewControllerDidStartRecording:(RecordingViewController *)recordingViewController;

// RecordingViewControllerDelegate method. Since recording stopped, notify our delegate.
- (void)recordingViewControllerDidStopRecording:(RecordingViewController *)recordingViewController;

@end
