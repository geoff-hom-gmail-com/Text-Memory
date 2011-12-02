//
//  DefaultData.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultData.h"
#import "Text.h"
#import "TextMemoryAppDelegate.h"

NSString *defaultDataStoreName = @"defaultDataStore.sqlite";

NSString *welcomeTextTitle = @"Welcome!";

// Private category for private methods.
@interface DefaultData ()

// Add the default data (from a property list) to the given context.
+ (void)addDefaultData:(NSManagedObjectContext *)theManagedObjectContext;

@end

@implementation DefaultData

@dynamic versionNumber;

+ (void)addDefaultData:(NSManagedObjectContext *)theManagedObjectContext {
	
	// Get the default data from the default-data property list.
	NSString *defaultDataPath = [[NSBundle mainBundle] pathForResource:@"default-data" ofType:@"plist"];
	NSFileManager *aFileManager = [[NSFileManager alloc] init];
	NSData *defaultDataXML = [aFileManager contentsAtPath:defaultDataPath];
	[aFileManager release];
	NSString *errorDesc = nil; 
	NSPropertyListFormat format;
	NSDictionary *rootDictionary = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:defaultDataXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
	if (!rootDictionary) { 
		NSLog(@"Error reading default plist: %@, format: %d", errorDesc, format);
	} else {
		
		// The property list is a dictionary of Texts: The key is the Text's title, and the value is the Text. Each Text is also represented by a dictionary.
		NSString *textTitleString;
		Text *aText;
		NSDictionary *intraTextDictionary;
		NSString *key;
		for (textTitleString in rootDictionary) {
			
			// Add the Text to the context.
			aText = (Text *)[NSEntityDescription insertNewObjectForEntityForName:@"Text" inManagedObjectContext:theManagedObjectContext];
			aText.title = textTitleString;
			aText.isDefaultData = YES;
			intraTextDictionary = [rootDictionary objectForKey:textTitleString];
			for (key in intraTextDictionary) {
				if ([key isEqualToString:@"Text"]) {
					aText.text = [intraTextDictionary objectForKey:key];
				}
			}
		}
	}
	
	NSError *error; 
	if (![theManagedObjectContext save:&error]) {
		NSLog(@"DefaultData: Error saving default data.");
		NSLog(@"DefaultData: Error is:%@", [error localizedDescription]);
		NSDictionary *aDictionary = [error userInfo];
		NSArray *anArray = (NSArray *)[aDictionary valueForKey:NSDetailedErrorsKey];
		for (error in anArray) {
			NSLog(@"testing error:%@", [error localizedDescription]);
		}
	}
	NSLog(@"Default data added from property list to store.");
}

+ (void)checkMainStore {
	
	// Fetch version from main store.
	NSFetchRequest *aFetchRequest = [[NSFetchRequest alloc] init];
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *aManagedObjectContext = [aTextMemoryAppDelegate managedObjectContext];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"DefaultData" inManagedObjectContext:aManagedObjectContext];
	[aFetchRequest setEntity:entityDescription];
	NSError *error;
	NSArray *defaultDataArray = [aManagedObjectContext executeFetchRequest:aFetchRequest error:&error];
	DefaultData *defaultData = [defaultDataArray objectAtIndex:0];
	[aFetchRequest release];
	
	// Get current version.
	NSNumber *aCurrentVersionNumber = [TextMemoryAppDelegate versionNumber];
	
	// Check if current version > version from main store. Was comparing NSNumbers directly, but aCurrentVersionNumber is derived from a string and stopped comparing properly in iOS 5.0.
    //if ([aCurrentVersionNumber compare:defaultData.versionNumber] == NSOrderedDescending) {
    if ( [aCurrentVersionNumber floatValue] > [defaultData.versionNumber floatValue] ) {
		
		NSLog(@"Newer version detected: updating default data.");
		NSLog(@"Current version number:%@", aCurrentVersionNumber);
		NSLog(@"Version number from main store:%@", defaultData.versionNumber);
		[DefaultData restore];
	}
}

+ (void)copyToMainStore {
	
	// Summary: Get texts from default-data store. Delete default texts from main store. Copy texts from default-data store to main store.
	
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	
	// Add default-data store to coordinator.
	NSPersistentStoreCoordinator *aPersistentStoreCoordinator = [aTextMemoryAppDelegate persistentStoreCoordinator];
	NSURL *defaultDataStoreURL = [[NSBundle mainBundle] URLForResource:defaultDataStoreName withExtension:nil];
	NSError *error;
	NSPersistentStore *defaultDataPersistentStore = [aPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:defaultDataStoreURL options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSReadOnlyPersistentStoreOption] error:&error];
	if (!defaultDataPersistentStore) {
		NSLog(@"Unresolved error adding default-data store: %@, %@", error, [error userInfo]);
	}
	
	// Fetch all texts from default-data store.
	
	NSFetchRequest *aFetchRequest = [[NSFetchRequest alloc] init];
	
	NSManagedObjectContext *aManagedObjectContext = [aTextMemoryAppDelegate managedObjectContext];
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Text" inManagedObjectContext:aManagedObjectContext];
	[aFetchRequest setEntity:entityDescription];
	[aFetchRequest setAffectedStores:[NSArray arrayWithObject:defaultDataPersistentStore]];
	NSArray *defaultTextsArray = [aManagedObjectContext executeFetchRequest:aFetchRequest error:&error];
	
	// Fetch all default-data texts from main store.
	
	NSURL *mainStoreURL = [[aTextMemoryAppDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:mainStoreName];
	NSPersistentStore *mainPersistentStore = [aPersistentStoreCoordinator persistentStoreForURL:mainStoreURL];
	[aFetchRequest setAffectedStores:[NSArray arrayWithObject:mainPersistentStore]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isDefaultData_ == YES"]; 
	[aFetchRequest setPredicate:predicate];
	NSArray *defaultTextsFromMainStoreArray = [aManagedObjectContext executeFetchRequest:aFetchRequest error:&error];
	
	[aFetchRequest release];
	
	// Delete default-data texts from main store.
	for (Text *aText in defaultTextsFromMainStoreArray) {
		[aManagedObjectContext deleteObject:aText];
	}
	
	// Create new texts for main store.
	Text *newText;
	for (Text *aText in defaultTextsArray) {
		
		newText = [aText clone];
		[aManagedObjectContext assignObject:newText toPersistentStore:mainPersistentStore];
	}
	
	// Remove default-data store from coordinator.
	[aPersistentStoreCoordinator removePersistentStore:defaultDataPersistentStore error:nil];
	
	// Check for version number in main store. If not there, add. Else, update.
	aFetchRequest = [[NSFetchRequest alloc] init];
	entityDescription = [NSEntityDescription entityForName:@"DefaultData" inManagedObjectContext:aManagedObjectContext];
	[aFetchRequest setEntity:entityDescription];
	NSArray *defaultDataArray = [aManagedObjectContext executeFetchRequest:aFetchRequest error:&error];
	[aFetchRequest release];
	DefaultData *aDefaultData;
	if (defaultDataArray.count == 0) {
		aDefaultData = (DefaultData *)[NSEntityDescription insertNewObjectForEntityForName:@"DefaultData" inManagedObjectContext:aManagedObjectContext];
	} else {
		aDefaultData = [defaultDataArray objectAtIndex:0];
	}
	aDefaultData.versionNumber = [TextMemoryAppDelegate versionNumber];
	NSLog(@"Version number:%@", aDefaultData.versionNumber);
	
	// Save.
	[aManagedObjectContext save:&error];
	
	NSLog(@"Default data copied to main store.");
}

+ (void)makeStore {
	
	NSLog(@"Making default-data store.");
	
	// Delete existing default-data store, if any.
	NSFileManager *aFileManager = [[NSFileManager alloc] init];
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	NSURL *documentDirectoryURL = [aTextMemoryAppDelegate applicationDocumentsDirectory];
	NSURL *defaultStoreURL = [documentDirectoryURL URLByAppendingPathComponent:defaultDataStoreName];
	BOOL deletionResult = [aFileManager removeItemAtURL:defaultStoreURL error:nil];
	NSLog(@"Deleted previous default-data store from application's document directory: %d", deletionResult);
	[aFileManager release];
	
	// Remove the main store from the persistent store coordinator.
	NSURL *mainStoreURL = [documentDirectoryURL URLByAppendingPathComponent:mainStoreName];
	NSPersistentStoreCoordinator *aPersistentStoreCoordinator = [aTextMemoryAppDelegate persistentStoreCoordinator];
	NSPersistentStore *mainPersistentStore = [aPersistentStoreCoordinator persistentStoreForURL:mainStoreURL];
	[aPersistentStoreCoordinator removePersistentStore:mainPersistentStore error:nil];
	
	// Add the default-data store to the persistent store coordinator.
	NSError *error = nil;
	NSPersistentStore *defaultPersistentStore = [aPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:defaultStoreURL options:nil error:&error];
	if (!defaultPersistentStore) {
		NSLog(@"Unresolved error making default store: %@, %@", error, [error userInfo]);
	} else {
		NSLog(@"Default store added: %@", [defaultStoreURL path]);
	}
	
	// Populate the store.
	[DefaultData addDefaultData:[aTextMemoryAppDelegate managedObjectContext]];
	
	// Remove the default-data store and add back the main store.
	[aPersistentStoreCoordinator removePersistentStore:defaultPersistentStore error:nil];
	[aPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:mainStoreURL options:nil error:nil];
}

+ (void)restore {
	
	NSLog(@"Restoring default data to main store.");
	[DefaultData copyToMainStore];
}

@end
