// 
//  Text.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Text.h"
#import "TextMemoryAppDelegate.h"

// Private category for private methods.
@interface Text ()

// The text, substituted with the same number of blanks per word, and preserving punctuation (except apostrophes).
@property (nonatomic, retain) NSString *blanksText_;

// Start key-value observing.
- (void)addObservers;

// An override of NSManagedObject. Add observers.
- (void)awakeFromFetch;

// An override of NSManagedObject. Initialize values. Add observers.
- (void)awakeFromInsert;

- (NSString *)makeBlanksText;

// Stop key-value observing.
- (void)removeObservers;

// An override of NSManagedObject. Remove observers. Note: This may not work with deletion-undo, since the observer will be removed upon deletion but then not added back. Can test when editing text live.
- (void)willTurnIntoFault;

@end


@implementation Text 

@dynamic isDefaultData_, text, title;
@synthesize blanksText_;

- (void)addObservers {

	// Watch for changes to the actual text.
	[self addObserver:self forKeyPath:@"text" options:0 context:nil];
}

- (void)awakeFromFetch {

	[super awakeFromFetch];
	[self addObservers];
}

- (void)awakeFromInsert {
	
	[super awakeFromInsert];
	[self addObservers];
	
	// Persistent data.
	NSLog(@"Awake from insert");
	self.isDefaultData = NO;
	self.title = @"A New Text";
	self.text = @"This is a new text."
        "\n\nTo edit the title and words of this text: First, tap \"Edit\" (top-left of the screen), then \"Edit Current Title and Text,\" to go into editing mode."
        "\n\nTo edit the title: While in editing mode, tap \"Rename Title\" (bottom-left)."
        "\n\nTo edit the words of this text: While in editing mode, tap the text."
        "\n\nTo select all of the text: While in editing mode, hold your finger on the text until a magnifying glass appears. Then let go, and a menu will appear with options to \"Select\" and \"Select All.\"" 
        "\n\nTo add text by pasting it: First, select your desired text and \"Copy\" or \"Cut\" it. (This can be done even in another app.) Then, follow the instructions above for selecting all of the text. The resulting menu will also have an option to \"Paste.\""
        "\n\nTo leave editing mode: Tap \"Cancel\" (top-left) to undo any changes to the words of this text, or tap \"Done\" (top-right) to save the changes."
        "\n\nTo delete this text: Tap the Trash Can (bottom-left), then \"Delete This Text.\" (If you accidentally tap the Trash Can, just tap anywhere except \"Delete This Text.\" Try it now to get a feel for it.)";
}

- (Text *)clone {
	
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aManagedObjectContext = [aTextMemoryAppDelegate managedObjectContext];
	
	Text *aText = (Text *)[NSEntityDescription insertNewObjectForEntityForName:@"Text" inManagedObjectContext:aManagedObjectContext];
	
    NSDictionary *attributesDictionary = [[NSEntityDescription entityForName:@"Text" inManagedObjectContext:aManagedObjectContext] attributesByName];
	
    for (NSString *attributeKey in attributesDictionary) {
        [aText setValue:[self valueForKey:attributeKey] forKey:attributeKey];
    }
	
    return aText;
}

/*
- (NSString *)createFirstLetterText {
	
	// this should be called only when the text changes. not each time it's loaded or each time the switch is done. only when first made and when edited.
	// I could trigger this by kvo on the text property.
	NSLog(@"Text: createFirstLetterText");
	
	// Go through the text, one character at a time. If previous character was a letter (or apostrophe) and this is also a letter (or apostrophe), then replace with a dash. Otherwise, keep it.
	//NSString *spaceString = @" ";
	NSString *dashString = @"_";
	NSMutableCharacterSet *letterEtAlMutableCharacterSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[letterEtAlMutableCharacterSet addCharactersInString:@"'"];
	NSCharacterSet *letterEtAlCharacterSet = [letterEtAlMutableCharacterSet copy];
	[letterEtAlMutableCharacterSet release];
	NSMutableString *aMutableFirstLetterText = [NSMutableString stringWithCapacity:self.text.length];
	BOOL previousCharacterWasLetter = NO;
	unichar character;
	NSString *characterToAddString;
	BOOL currentCharacterIsLetter;
	BOOL addSpace;
	for (int i = 0; i < self.text.length; i++) {
		
		currentCharacterIsLetter = NO;
		character = [self.text characterAtIndex:i];
		if ( [letterEtAlCharacterSet characterIsMember:character] ) {
			currentCharacterIsLetter = YES;
		}
		
		addSpace = NO;
		if (previousCharacterWasLetter && currentCharacterIsLetter) {
			addSpace = YES;
		}
		
		if (addSpace) {
			[aMutableFirstLetterText appendString:dashString];
		} else {
			characterToAddString = [NSString stringWithCharacters:&character length:1];
			[aMutableFirstLetterText appendString:characterToAddString];
		}
		
		previousCharacterWasLetter = currentCharacterIsLetter;
	}
	[letterEtAlCharacterSet release];
    //NSLog(@"T cFLT:%@", aMutableFirstLetterText);
	return aMutableFirstLetterText;
}
 */

- (void)dealloc {
    
    [blanksText_ release];
    [super dealloc];
}

- (NSString *)blanksText {
    
    if (self.blanksText_ == nil) {
        
        self.blanksText_ = [self makeBlanksText];
    }
    return self.blanksText_;
}

- (BOOL)isDefaultData {
	
	return [self.isDefaultData_ boolValue];
}

- (NSString *)makeBlanksText {
    
    // Each word will be replaced by this string. 
    NSString *blanksString = @"__";
	
    // For rough timing of how long to make the blanks text.
    //NSLog(@"Starting makeBlanksText");
    
    // Go through the text to build the blanks text. If a letter (or apostrophe), use the number of blanks per word, then ignore letters (and apostrophes) until a non-letter (and non-apostrophe). Otherwise (e.g., whitespace, other punctuation), use that.
    
    // Make a non-mutable character set of letters and an apostrophe.
    NSMutableCharacterSet *letterEtAlMutableCharacterSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[letterEtAlMutableCharacterSet addCharactersInString:@"'"];
	NSCharacterSet *letterEtAlCharacterSet = [letterEtAlMutableCharacterSet copy];
	[letterEtAlMutableCharacterSet release];
    
	NSMutableString *aBlanksTextMutableString = [NSMutableString stringWithCapacity:self.text.length];
	unichar character;
	NSString *characterToAddString;
	BOOL addBlanks;
    BOOL currentCharacterIsLetter;
	BOOL previousCharacterWasLetter = NO;
    BOOL skip;
	for (int i = 0; i < self.text.length; i++) {
		
		currentCharacterIsLetter = NO;
		character = [self.text characterAtIndex:i];
		if ( [letterEtAlCharacterSet characterIsMember:character] ) {
			currentCharacterIsLetter = YES;
		}
		
        skip = NO;
		addBlanks = NO;
		if (currentCharacterIsLetter) {
            
            if (previousCharacterWasLetter) {
                
                skip = YES;
            } else {
                
                addBlanks = YES;
            }
        }
        
        // Add characters, if any.
        if (skip) {
            
        } else if (addBlanks) {
            
			[aBlanksTextMutableString appendString:blanksString];
		} else {
            
			characterToAddString = [NSString stringWithCharacters:&character length:1];
			[aBlanksTextMutableString appendString:characterToAddString];
		}	
        
        // Set flags for next run through loop.
        if (currentCharacterIsLetter) {
            
            previousCharacterWasLetter = YES;
		} else {
            
            previousCharacterWasLetter = NO;
        }
	}
	[letterEtAlCharacterSet release];
    
    // For rough timing of how long to make the blanks text.
    //NSLog(@"done makeBlanksText");
    
    return aBlanksTextMutableString;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	// If the text was changed, then update the text for each text mode.
	if ([keyPath isEqualToString:@"text"]) {
		
		NSLog(@"Text observeValueForKeyPath: Text changed.");
		//self.firstLetterText = [self createFirstLetterText];
        self.blanksText_ = nil;
	}
}

- (void)removeObservers {

	// Stop watching for changes to the text.
	[self removeObserver:self forKeyPath:@"text"];
}

- (void)setIsDefaultData:(BOOL)value {
	
	self.isDefaultData_ = [NSNumber numberWithBool:value];
}

- (void)willTurnIntoFault {
	
	[super willTurnIntoFault];
	[self removeObservers];
}

@end
