//
//  PlaybackViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import "PlaybackViewController.h"

// Private category for private methods.
@interface PlaybackViewController ()

// Whether the audio player was playing when the user moved the slider.
@property (nonatomic) BOOL audioPlayerWasPlaying;

// Start of status label, noting whether playing or paused (to user).
@property (nonatomic, retain) NSString *playingOrPausedString;

// Repeating timer to update slider thumb with current time.
@property (nonatomic, retain) NSTimer *sliderTimer;

@end

@implementation PlaybackViewController

@synthesize audioPlayer, delegate, playheadSlider, playOrPauseButton, statusLabel, voiceRecordingURL;
@synthesize audioPlayerWasPlaying, playingOrPausedString, sliderTimer;

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    
    [self.sliderTimer invalidate];
    self.playingOrPausedString = @"Paused at";
    [self.delegate playbackViewControllerDidStopPlaying:self];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    [self.sliderTimer invalidate];
    self.statusLabel.text = [NSString stringWithFormat:@"Duration: %.0f sec.", 
        self.audioPlayer.duration];
    self.playingOrPausedString = @"Paused at";
    self.playheadSlider.value = 0;
    [self.delegate playbackViewControllerDidStopPlaying:self];
}

- (void)clearAudioPlayer {
    
    [self.audioPlayer stop];
    [self.sliderTimer invalidate];
    self.audioPlayer.delegate = nil;
    self.audioPlayer = nil;
}

- (void)dealloc {
	
    self.audioPlayer.delegate = nil;
    [audioPlayer release];
    [playheadSlider release];
    [playOrPauseButton release];
    [statusLabel release];
    [voiceRecordingURL release];
    
    [playingOrPausedString release];
    [sliderTimer release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)handleSliderReleased:(UISlider *)theSlider {
    
    if (self.audioPlayerWasPlaying) {
        
        [self playOrPause];
    }
}

- (IBAction)handleSliderTouchedDown:(UISlider *)theSlider {
    
    if (self.audioPlayer.playing) {
        
        [self.audioPlayer pause];
        [self.sliderTimer invalidate];
        self.audioPlayerWasPlaying = YES;
    } else {
        
        self.audioPlayerWasPlaying = NO;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Custom initialization
        self.playingOrPausedString = @"Paused at";
    }
    return self;
}

- (IBAction)movePlayhead:(UISlider *)theSlider {
    
    // If the current time is set to the duration or more, then the current time automatically becomes 0. So do something only if the slider value is less than the duration.
    if (theSlider.value < theSlider.maximumValue) {
        
        self.audioPlayer.currentTime = theSlider.value;
        self.statusLabel.text = [NSString stringWithFormat:@"%@ %.0f sec.", 
            self.playingOrPausedString, self.audioPlayer.currentTime];
    }
}

- (IBAction)playOrPause {

    // If not playing, start playing.
    if (!self.audioPlayer.playing) {
        
        // This may not be needed. But sometimes there was a pop or clipping sound at the start of a recording. Hopefully this (or audioRecorder prepareToRecord) fixes it.
        //[self.audioPlayer prepareToPlay];
        
        [self.audioPlayer play];
        
        // Sometimes, when the user slides the playhead to the start, the current time becomes negative. We'll fix that here.
        if (self.audioPlayer.currentTime < 0) {
            
            self.audioPlayer.currentTime = 0;
        }
        
        self.playingOrPausedString = @"Playing:";
        
        // Deactivate any previous timer first. (Just in case.)
        [self.sliderTimer invalidate];
        
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self 
            selector:@selector(updateSliderPlayhead:) userInfo:nil repeats:YES];
        [self.delegate playbackViewControllerDidStartPlaying:self];
    } else {
        
        [self.audioPlayer pause];
        [self.sliderTimer invalidate];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        self.playingOrPausedString = @"Paused at";
        [self.delegate playbackViewControllerDidStopPlaying:self];
    }
    self.statusLabel.text = [NSString stringWithFormat:@"%@ %.0f sec.", 
        self.playingOrPausedString, self.audioPlayer.currentTime];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Return YES for supported orientations
	return YES;
}

- (void)updateSliderPlayhead:(NSTimer *)theTimer {
    
    self.statusLabel.text = [NSString stringWithFormat:@"Playing: %.0f sec.", 
        self.audioPlayer.currentTime];
    self.playheadSlider.value = self.audioPlayer.currentTime;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.playheadSlider.value = 0;
    self.playheadSlider.minimumValue = 0;
    
    // Set default (initial) size.
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.playheadSlider = nil;
    self.playOrPauseButton = nil;
    self.statusLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Check if audio player already present. If not, try to make one. If successful, keep it and enable appropriate buttons.
    if (self.audioPlayer == nil) {
        
        AVAudioPlayer *anAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.voiceRecordingURL error:nil];
        if (anAudioPlayer == nil || anAudioPlayer.duration == 0) {
            
            self.statusLabel.text = @"Nothing to play yet.";
            self.playOrPauseButton.enabled = NO;
            self.playheadSlider.maximumValue = 0;
        } else {
            
            anAudioPlayer.delegate = self;
            self.audioPlayer = anAudioPlayer;
            self.statusLabel.text = [NSString stringWithFormat:@"Duration: %.0f sec.", anAudioPlayer.duration];
            self.playOrPauseButton.enabled = YES;
            self.playheadSlider.maximumValue = anAudioPlayer.duration;
        }
        [anAudioPlayer release];
        self.playheadSlider.value = 0;
    }
}

@end
