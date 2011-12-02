//
//  TextMemoryAppDelegate.h
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

// When using a fade transition (e.g., CATransition), how long to take.
extern CGFloat fadeTransitionDuration;

// Name of the file for the main Core Data store.
extern NSString *mainStoreName;

// Whether to make the default Core Data store.
extern BOOL makeDefaultDataStore;

// Whether to reset the default data (in the main store).
extern BOOL restoreDefaultData;

@interface TextMemoryAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

// Returns the persistent store coordinator for the application. If the coordinator doesn't already exist, it is created and the application's store added to it. (If the main store doesn't exist, the default-data store is copied to the main store.)
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

// Save the main managed object context to disk.
- (void)saveContext;

// Return the current version number.
+ (NSNumber *)versionNumber;

@end

