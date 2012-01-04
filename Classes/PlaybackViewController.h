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

@property (nonatomic, retain) IBOutlet UIButton *fastForwardButton;

@property (nonatomic, retain) IBOutlet UIButton *playButton;

@property (nonatomic, retain) IBOutlet UIButton *rewindButton;

// Label for noting whether a recording is present.
@property (nonatomic, retain) IBOutlet UILabel *testLabel;

// URL of the voice recording to play.
@property (nonatomic, retain) NSURL *voiceRecordingURL;

// AVAudioPlayerDelegate method. Since playback finished, notify our delegate.
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;

- (IBAction)fastForward;

- (IBAction)playOrPause;

- (IBAction)rewindToStart;

@end
