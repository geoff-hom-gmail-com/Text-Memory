//
//  OverlayView.h
//  Text-to-First-Letters

// Invisible/empty view for positioning above the UI to detect touch events. Can detect touch events that are only outside a given text view's text.
//
//  Created by Geoffrey Hom on 10/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OverlayView : UIView {
}


// Text view to let touch events pass through to. If the text is shorter than the text view, this will apply only to the rectangle bounding the actual text.
@property (nonatomic, retain) IBOutlet UITextView *textViewToIgnore;

// UIView method override. If the given point is in the text view to ignore, then return NO. Else, perform normally (call super).
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;

@end
