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

@end

@implementation PlaybackViewController

@synthesize audioPlayer, delegate, fastForwardButton, playButton, rewindButton, testLabel, voiceRecordingURL;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    self.testLabel.text = @"Playback done.";
    self.rewindButton.enabled = NO;
    [self.delegate playbackViewControllerDidStopPlaying:self];
}

- (void)dealloc {
	
    [audioPlayer release];
    [fastForwardButton release];
    [playButton release];
    [rewindButton release];
    [testLabel release];
    [voiceRecordingURL release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)fastForward {
    
    ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)playOrPause {
    
    // If not playing, start playing.
    if (!self.audioPlayer.playing) {
        
        [self.audioPlayer play];
        self.testLabel.text = @"Playback started.";
        self.rewindButton.enabled = YES;
        [self.delegate playbackViewControllerDidStartPlaying:self];
    } else {
        
        [self.audioPlayer pause];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        self.testLabel.text = @"Playback paused.";
        [self.delegate playbackViewControllerDidStopPlaying:self];
    }
}

- (IBAction)rewindToStart {
    
    self.audioPlayer.currentTime = 0;
    
    // If not playing, then disable rewind button, since it can't do anything.
    if (!self.audioPlayer.playing) {
        
        self.rewindButton.enabled = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Return YES for supported orientations
	return YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    // Set default (initial) size.
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.fastForwardButton = nil;
    self.playButton = nil;
    self.rewindButton = nil;
    self.testLabel = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Check if audio player already present. If not, try to make one. If successful, keep it and enable appropriate buttons.
    if (self.audioPlayer == nil) {
        
        AVAudioPlayer *anAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.voiceRecordingURL error:nil];
        if (anAudioPlayer == nil) {
            
            self.testLabel.text = @"Recording not found.";
            self.fastForwardButton.enabled = NO;
            self.playButton.enabled = NO;
            self.rewindButton.enabled = NO;
        } else {
            
            anAudioPlayer.delegate = self;
            self.audioPlayer = anAudioPlayer;
            self.testLabel.text = [NSString stringWithFormat:@"Duration: %.0f", anAudioPlayer.duration];
            self.fastForwardButton.enabled = YES;
            self.playButton.enabled = YES;
            self.rewindButton.enabled = NO;
        }
        [anAudioPlayer release];
    }
}

@end
