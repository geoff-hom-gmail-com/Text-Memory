//
//  PlaybackViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import <UIKit/UIKit.h>

@class PlaybackViewController;

@protocol PlaybackViewControllerDelegate

// Sent after playback has started.
- (void)playbackViewControllerDidStartPlaying:(PlaybackViewController *)sender;

// Sent after playback has stopped.
- (void)playbackViewControllerDidStopPlaying:(PlaybackViewController *)sender;

@end

@interface PlaybackViewController : UIViewController <AVAudioPlayerDelegate>

@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, assign) id <PlaybackViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet UISlider *playheadSlider;

@property (nonatomic, retain) IBOutlet UIButton *playOrPauseButton;

// remove this?
@property (nonatomic, retain) IBOutlet UIButton *stopButton;

// Label for showing playback status.
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

// URL of the voice recording to play.
@property (nonatomic, retain) NSURL *voiceRecordingURL;

// AVAudioPlayerDelegate method. Since playback interrupted, notify our delegate.
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player;

// AVAudioPlayerDelegate method. Since playback finished, notify our delegate.
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;

// The audio file may be compromised. Delete the current audio player, etc.
- (void)clearAudioPlayer;

// If the audio player was playing when the slider was moved, resume playing.
- (IBAction)handleSliderReleased:(UISlider *)theSlider;

// Since the playhead will be moving, if the audio player is playing, then pause it.
- (IBAction)handleSliderTouchedDown:(UISlider *)theSlider;

// Move the audio player's current time to match the slider's value. 
- (IBAction)movePlayhead:(UISlider *)theSlider;

- (IBAction)playOrPause;

// Update the slider's playhead to the current time.
- (void)updateSliderPlayhead:(NSTimer *)theTimer;

@end
