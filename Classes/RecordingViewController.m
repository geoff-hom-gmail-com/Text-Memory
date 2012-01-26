//
//  RecordingAndPlaybackViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioSession.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "RecordingViewController.h"

// Private category for private methods.
@interface RecordingViewController ()

// Not really for playing. Only for pausing playback to work around popping-sound bug.
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@property (nonatomic, retain) AVAudioRecorder *audioRecorder;

// Whether prepareToRecord: was called yet.
@property (nonatomic) BOOL recorderIsPrepared;

// URL to record the audio to. When the recording is finished, it is moved to the voice recording URL. This ensures that the playback URL isn't overwritten until a new recording is finished.
@property (nonatomic, retain) NSURL *temporaryRecordingURL;

@end

@implementation RecordingViewController

@synthesize delegate, recordOrPauseButton, statusLabel, stopButton, voiceRecordingURL;
@synthesize audioPlayer, audioRecorder, recorderIsPrepared, temporaryRecordingURL;

- (void)dealloc {
	
    [audioPlayer release];
    [audioRecorder release];
    [temporaryRecordingURL release];
    
    [recordOrPauseButton release];
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
        
        NSString *temporaryDirectoryString = NSTemporaryDirectory();
        NSString *voiceRecordingPathString = [temporaryDirectoryString stringByAppendingString:@"temporaryRecording.caf"];
        NSURL *aURL = [NSURL fileURLWithPath:voiceRecordingPathString];
        self.temporaryRecordingURL = aURL;
        
        // Can adjust settings if the voice recordings take up too much space.
        NSDictionary *recordingSettingsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithFloat:44100.0], AVSampleRateKey, 
             [NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
             [NSNumber numberWithInt:1], AVNumberOfChannelsKey, 
             [NSNumber numberWithInt:AVAudioQualityMax], AVEncoderAudioQualityKey, nil];
        
        AVAudioRecorder *anAudioRecorder = [[AVAudioRecorder alloc] initWithURL:self.temporaryRecordingURL settings:recordingSettingsDictionary error:nil];
        self.audioRecorder = anAudioRecorder;
        [anAudioRecorder release];
        self.recorderIsPrepared = NO;
        
        // Create dummy audio player.
        NSURL *dummyAudioFileURL = [[NSBundle mainBundle] URLForResource:@"dummy.caf" withExtension:nil];
        AVAudioPlayer *anAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:dummyAudioFileURL error:nil];
        self.audioPlayer = anAudioPlayer;
        [anAudioPlayer release];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)recordOrPause {
    
    if (!self.audioRecorder.recording) {
        
        [self.audioRecorder record];
        
        // Uncomment this to make a new dummy recording (dummy.caf). The file will be in the temporary directory as the voice recording. Rename it and replace the dummy recording in the main bundle.
        //[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(stopRecording) userInfo:nil repeats:NO];
        
        self.stopButton.enabled = YES;
        self.statusLabel.text = @"Recording started.";
        [self.delegate recordingViewControllerDidStartRecording:self];
    } else {
        
        [self.audioRecorder pause];
        self.statusLabel.text = @"Recording paused.";
        [self.delegate recordingViewControllerDidPauseRecording:self];
    }
}

- (IBAction)stopRecording {
    
    [self.audioRecorder stop];
    self.stopButton.enabled = NO;
    self.statusLabel.text = @"Recording done.";
    
    // Move file to URL for playback.
    NSFileManager *aFileManager = [[NSFileManager alloc] init];
    [aFileManager removeItemAtURL:self.voiceRecordingURL error:nil];
    [aFileManager moveItemAtURL:self.temporaryRecordingURL toURL:self.voiceRecordingURL error:nil];
    [aFileManager release];
    
    [self.delegate recordingViewControllerDidStopRecording:self];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    // Bug fix. On an iPad 1 with iOS 5 with earphones in, when recording there is often a noticeable popping sound at the start of the recording. This doesn't happen if the most recent audio player is paused. Since the user may have just finished playback, we'll play and pause a dummy audio player before recording. This should be very fast (< 0.07 s) except for the first time. So to keep the UI responsive, we'll do it here rather than downstream, like in "recordOrPause."
//    NSLog(@"ReVC vDA before play");
    self.audioPlayer.currentTime = 0;
    [self.audioPlayer play];
    [self.audioPlayer pause];
//    NSLog(@"ReVC vDA after pause");
    
    if (!self.recorderIsPrepared) {
        
//        NSLog(@"ReVC before prepareToRecord");
        self.recorderIsPrepared = [self.audioRecorder prepareToRecord];
//        NSLog(@"ReVC after prepareToRecord");
    }
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.recordOrPauseButton.enabled = YES;
    self.stopButton.enabled = NO;
    self.statusLabel.text = @"";
    
    // Set default (initial) size.
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.recordOrPauseButton = nil;
    self.statusLabel = nil;
    self.stopButton = nil;
}

@end
