//
//  RecordingAndPlaybackController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVAudioSession.h>
#import "PlaybackViewController.h"
#import "RecordingAndPlaybackController.h"
#import "RecordingViewController.h"

// Filename to record sound to, temporarily.
NSString *voiceRecordingFilenameString = @"voiceRecording.caf";

// Private category for private methods.
@interface RecordingAndPlaybackController ()

// View controller for the mode being shown.
@property (nonatomic, retain) UIViewController *currentViewController;

// View controller for the playback mode.
@property (nonatomic, retain) PlaybackViewController *playbackViewController;

// View controller for the recording mode.
@property (nonatomic, retain) RecordingViewController *recordingViewController;

// Segmented control for switching between modes.
@property (nonatomic, retain) UISegmentedControl *segmentedControl;

@property (nonatomic, retain) NSURL *voiceRecordingURL;

// The segmented control's index changed, so show the appropriate UI: Recording or playback.
- (void)indexDidChangeForSegmentedControl;

@end

@implementation RecordingAndPlaybackController

@synthesize delegate, navigationController;
@synthesize currentViewController, playbackViewController, recordingViewController, segmentedControl, voiceRecordingURL;

- (void)dealloc {
    
    [currentViewController release];
    self.playbackViewController.delegate = nil;
    [playbackViewController release];
    self.recordingViewController.delegate = nil;
    [recordingViewController release];
    [segmentedControl release];
    [voiceRecordingURL release];
    
    [navigationController release];
    
    [super dealloc];
}

- (void)indexDidChangeForSegmentedControl {
    
    // Assume 0 is "Record." 1 is "Play."
    if (self.segmentedControl.selectedSegmentIndex == 0) {
		
        self.currentViewController = self.recordingViewController;
	} else {
		
        self.currentViewController = self.playbackViewController;        
	}
    
    // Keep the segmented control visible.
    self.currentViewController.navigationItem.titleView = self.segmentedControl;
    
    // Show the appropriate view.
    NSArray *incomingViewControllerArray = [NSArray arrayWithObject:self.currentViewController];
    [self.navigationController setViewControllers:incomingViewControllerArray animated:NO];
}

- (id)init {
    
    self = [super init];
    if (self != nil) {
        
        NSString *temporaryDirectoryString = NSTemporaryDirectory();
        NSString *voiceRecordingPathString = [temporaryDirectoryString stringByAppendingString:voiceRecordingFilenameString];
        NSURL *aURL = [NSURL fileURLWithPath:voiceRecordingPathString];
        self.voiceRecordingURL = aURL;
        
        RecordingViewController *aRecordingViewController = [[RecordingViewController alloc] init];
        aRecordingViewController.delegate = self;
        aRecordingViewController.voiceRecordingURL = self.voiceRecordingURL;
		self.recordingViewController = aRecordingViewController;
        [aRecordingViewController release];
        
        PlaybackViewController *aPlaybackViewController = [[PlaybackViewController alloc] init];
        aPlaybackViewController.delegate = self;
        aPlaybackViewController.voiceRecordingURL = self.voiceRecordingURL;
		self.playbackViewController = aPlaybackViewController;
        [aPlaybackViewController release];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:self.recordingViewController];
        self.navigationController = aNavigationController;
        [aNavigationController release];
        
        UISegmentedControl *aSegmentedControl = [ [UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Recording", @"Playback", nil] ];
        aSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        //testing
        // light blue
        UIColor *aMediumLightColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:1];
        // light gray
        //UIColor *aMediumLightColor = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
        aSegmentedControl.tintColor = aMediumLightColor;
        
        aSegmentedControl.selectedSegmentIndex = 0;
        [aSegmentedControl addTarget:self action:@selector(indexDidChangeForSegmentedControl) forControlEvents:UIControlEventValueChanged];
        self.segmentedControl = aSegmentedControl;
        [aSegmentedControl release];
        
        [self indexDidChangeForSegmentedControl];
    }
    return self;
}

- (void)playbackViewControllerDidStartPlaying:(PlaybackViewController *)playbackViewController {
    
    [self.delegate recordingAndPlaybackControllerDidStartPlaying:self];
}

- (void)playbackViewControllerDidStopPlaying:(PlaybackViewController *)playbackViewController {
    
    [self.delegate recordingAndPlaybackControllerDidStopPlaying:self];
}

- (void)recordingViewControllerDidStartRecording:(RecordingViewController *)recordingViewController {
    
    [self.delegate recordingAndPlaybackControllerDidStartRecording:self];
}

- (void)recordingViewControllerDidStopRecording:(RecordingViewController *)recordingViewController {
    
    // stop playback here or when starting recording? try this first.
    self.playbackViewController.audioPlayer = nil;
    
    [self.delegate recordingAndPlaybackControllerDidStopRecording:self];
}

@end
