//
//  OverlayView.m
//  Text-to-First-Letters
//
//  Created by Geoffrey Hom on 10/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

@synthesize textViewToIgnore;

- (void)dealloc {
	
	[textViewToIgnore release];
    [super dealloc];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code.
 }
 */

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	
	// Check if the point is in the actual text bounds of the text view to ignore. The point is in local coordinates to the overlay. The text view to ignore is not a subview of the overlay, so we'll convert the actual text bounds to coordinates local to the overlay.
	
	BOOL answer;
	if (self.textViewToIgnore) {
		
		// If the text is longer than the text view, use the text view's height. 
		CGSize textSize = self.textViewToIgnore.contentSize;
		if (textSize.height > self.textViewToIgnore.frame.size.height) {
			textSize.height = self.textViewToIgnore.frame.size.height;
		}
		
		// Assume the actual text starts at the text view's origin. 
		CGPoint newOrigin = [self convertPoint:CGPointMake(0, 0) fromView:self.textViewToIgnore];
		
		// If the text is longer than the text view, then the converted y-coordinate will be off. Assume the overlay and the text view start at the same y-coordinate, so the y should be 0.
		CGRect actualTextRect = CGRectMake(newOrigin.x, 0, textSize.width, textSize.height);
		
		//NSLog(@"new origin:%@", NSStringFromCGPoint(newOrigin) );
		//NSLog(@"point:%@", NSStringFromCGPoint(point) );
		//NSLog(@"textSize:%@", NSStringFromCGSize(textSize) );
		//NSLog(@"actualTextRect:%@", NSStringFromCGRect(actualTextRect) );
		
		if (CGRectContainsPoint(actualTextRect, point) ) {
			
			answer = NO;
		} else {
			
			answer = [super pointInside:point withEvent:event];
		}
	} else {
		
		answer = [super pointInside:point withEvent:event];
	}

	return answer;
}

@end
