//
//  RecordingAndPlaybackViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioSession.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "RecordingViewController.h"

// Private category for private methods.
@interface RecordingViewController ()

@property (nonatomic, retain) AVAudioRecorder *audioRecorder;

@end

@implementation RecordingViewController

@synthesize delegate, startButton, statusLabel, stopButton, voiceRecordingURL;
@synthesize audioRecorder;

- (void)dealloc {
	
    [audioRecorder release];
    
    [startButton release];
    [statusLabel release];
    [stopButton release];
    [voiceRecordingURL release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)startRecording {
    
    [self.audioRecorder record];
    self.startButton.enabled = NO;
    self.stopButton.enabled = YES;
    self.statusLabel.text = @"Recording started.";
    
    [self.delegate recordingViewControllerDidStartRecording:self];
}

- (IBAction)stopRecording {
    
    [self.audioRecorder stop];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    self.startButton.enabled = YES;
    self.stopButton.enabled = NO;
    self.statusLabel.text = @"Recording done.";
    
    [self.delegate recordingViewControllerDidStopRecording:self];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.statusLabel.text = @"";
    //self.startButton.enabled = YES;
    //self.stopButton.enabled = NO;
    
    // Set default (initial) size.
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.startButton = nil;
    self.statusLabel = nil;
    self.stopButton = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Check if audio recorder already present. If not, try to make one. If successful, keep it and enable appropriate buttons.
    if (self.audioRecorder == nil) {
        
        NSDictionary *recordingSettingsDictionary = nil;
        /*
        NSDictionary *recordingSettingsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:44100.0], AVSampleRateKey, [NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
            [NSNumber numberWithInt:1], AVNumberOfChannelsKey, 
            [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey, nil];
        */
        AVAudioRecorder *anAudioRecorder = [[AVAudioRecorder alloc] initWithURL:self.voiceRecordingURL settings:recordingSettingsDictionary error:NULL];
        if (anAudioRecorder == nil) {
            
            self.startButton.enabled = NO;
            self.stopButton.enabled = NO;
        } else {
            
            self.audioRecorder = anAudioRecorder;
            self.startButton.enabled = YES;
            self.stopButton.enabled = NO;
        }
        [anAudioRecorder release];
    }
}


@end
