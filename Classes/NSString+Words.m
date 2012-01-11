//
//  NSString+Words.m
//  Text Memory
//
//  Created by Geoffrey Hom on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Words.h"

@implementation NSString (Words)

- (NSRange)rangeOfWordAtIndex:(NSUInteger)index {
    
    NSRange wordRange;
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    unichar aChar = [self characterAtIndex:index];
    
    if ([whitespaceAndNewlineCharacterSet characterIsMember:aChar]) {
        
        wordRange = NSMakeRange(NSNotFound, 0);
    } else {
        
        // Search backward for whitespace, from (index - 1) to start. Since we want the start of the word and not actual whitespace, add one to the start.
        NSRange rangeToCheck = NSMakeRange(0, index);
        NSRange startOfWordRange = [self rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:NSBackwardsSearch range:rangeToCheck];
        if (startOfWordRange.location == NSNotFound) {
            
            startOfWordRange.location = 0;
        } else {
            
            startOfWordRange.location = startOfWordRange.location + 1;
        }
        
        // Search forward for whitespace, from index to end. Since we want the end of the word and not actual whitespace, subtract one from the end.
        rangeToCheck = NSMakeRange(index, self.length - index);
        NSRange endOfWordRange = [self rangeOfCharacterFromSet:whitespaceAndNewlineCharacterSet options:0 range:rangeToCheck];
        if (endOfWordRange.location == NSNotFound) {
            
            endOfWordRange.location = self.length - 1;
        } else {
            
            endOfWordRange.location = endOfWordRange.location - 1;
        }
    
        wordRange = NSMakeRange(startOfWordRange.location, endOfWordRange.location - startOfWordRange.location + 1);
    }
    return wordRange;
};

- (NSUInteger)startOfNthWord:(NSUInteger)number {
    
    return [self startOfNthWord:number afterRange:NSMakeRange(0, 0)];
};
     
- (NSUInteger)startOfNthWord:(NSUInteger)number afterRange:(NSRange)theRange {
    
    NSUInteger startOfNthWordUInteger = self.length;
    
    // Search forward from the given range, counting words until the nth. Then get the start of that word. 
    
    NSUInteger startIndexUInteger;
    if (theRange.length == 0) {
        
        startIndexUInteger = theRange.location;
    } else {
        
        startIndexUInteger = theRange.location + theRange.length;
    }
    
    // Searching forward, a word was found if whitespace (or the start), followed by non-whitespace. The next word is whitespace, followed by non-whitespace.
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    unichar character;
    BOOL characterIsNonWhitespace;
    BOOL previousCharacterWasWhitespace = YES;
    NSUInteger wordCount = 0;
    for (int i = startIndexUInteger; i < self.length; i++) {
		
		character = [self characterAtIndex:i];
        characterIsNonWhitespace = ![whitespaceAndNewlineCharacterSet characterIsMember:character];
        if (characterIsNonWhitespace && previousCharacterWasWhitespace) {
            
            wordCount++;
            if (wordCount == number) {
                
                startOfNthWordUInteger = i;
                break;
            }
        }
        previousCharacterWasWhitespace = !characterIsNonWhitespace;
    }
    
    return startOfNthWordUInteger;
}

- (NSUInteger)wordCount {
    
    NSUInteger wordCount = 0;
    
    // Searching forward, a word was found if whitespace (or the start), followed by non-whitespace. The next word is whitespace, followed by non-whitespace.
    
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    unichar character;
    BOOL characterIsNonWhitespace;
    BOOL previousCharacterWasWhitespace = YES;
    for (int i = 0; i < self.length; i++) {
		
		character = [self characterAtIndex:i];
        characterIsNonWhitespace = ![whitespaceAndNewlineCharacterSet characterIsMember:character];
        if (characterIsNonWhitespace && previousCharacterWasWhitespace) {
            
            wordCount++;
        }
        previousCharacterWasWhitespace = !characterIsNonWhitespace;
    }
    
    return wordCount;
}

@end
