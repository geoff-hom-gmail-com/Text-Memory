//
//  NSString+Words.h
//  Text Memory
//
//  Created by Geoffrey Hom on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Words)

// Return the range of the word that includes the given index. The range includes punctuation. If the index is at whitespace, then return NSNotFound.
- (NSRange)rangeOfWordAtIndex:(NSUInteger)index;

// Return the index of the start of the nth word in this string. If there is no nth word, then return length of this string.
- (NSUInteger)startOfNthWord:(NSUInteger)number;

// Return the index of the start of the nth word after the given range. If the range's length is 0, then this method starts counting at the range's location. If there is no nth word, then return length of this string.
- (NSUInteger)startOfNthWord:(NSUInteger)number afterRange:(NSRange)theRange;

// Return the number of words in this string. For this method, a word is a collection of non-whitespace characters. So a period (or blank/underscore) flanked by whitespace would be one word.
- (NSUInteger)wordCount;

@end
