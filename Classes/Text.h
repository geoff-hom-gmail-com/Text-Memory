//
//  Text.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Text :  NSManagedObject  {
}

@property (nonatomic, retain) NSString *firstLetterText;

// This is a BOOL but under Core Data, so it must be an NSNumber.
@property (nonatomic, retain) NSNumber *isDefaultData_;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *text;

@property (nonatomic, retain) NSString *underscoreText;

// Return a new instance with the same properties as this one. 
- (Text *)clone;

// Return the blanks text. If not made yet, make it.
- (NSString *)blanksText;

// Return isDefaultData_ as BOOL.
- (BOOL)isDefaultData;

// For key-value observing (KVO). If the text was changed, then update stuff.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

// Set isDefaultData_ with BOOL.
- (void)setIsDefaultData:(BOOL)value;

@end

