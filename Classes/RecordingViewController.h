//
//  RecordingAndPlaybackViewController.h
//  Text Memory
//
//  Created by Geoffrey Hom on 12/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RecordingViewController;

@protocol RecordingViewControllerDelegate

// Sent after recording has started.
- (void)recordingViewControllerDidStartRecording:(RecordingViewController *)sender;

// Sent after recording has stopped.
- (void)recordingViewControllerDidStopRecording:(RecordingViewController *)sender;

@end

@interface RecordingViewController : UIViewController {
    
}

@property (nonatomic, assign) id <RecordingViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet UIButton *startButton;

// Label for showing recording status.
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

@property (nonatomic, retain) IBOutlet UIButton *stopButton;

// URL of the voice recording to play.
@property (nonatomic, retain) NSURL *voiceRecordingURL;

- (IBAction)startRecording;

- (IBAction)stopRecording;

@end
