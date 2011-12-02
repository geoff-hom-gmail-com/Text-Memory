//
//  TextMemoryAppDelegate.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultData.h"
#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TextMemoryAppDelegate.h"

CGFloat fadeTransitionDuration = 0.5;

NSString *mainStoreName = @"Text_Memory.sqlite";

// Set to YES to skip regular operation and make default-data store.
BOOL makeDefaultDataStore = NO;

// Set to YES to force the default data to be restored. The user's texts should be unaffected. 
BOOL restoreDefaultData = NO;

@implementation TextMemoryAppDelegate

@synthesize window;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
	if (makeDefaultDataStore) {
		
		[DefaultData makeStore];
	} else {
		
		// If the main store exists, then we can restore or check its default data.
		NSURL *mainStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:mainStoreName];
		NSString *mainStorePath = [mainStoreURL path];
		NSFileManager *aFileManager = [[NSFileManager alloc] init];
		if ([aFileManager fileExistsAtPath:mainStorePath]) {
			if (restoreDefaultData) {
				[DefaultData restore];
			} else {
				[DefaultData checkMainStore];
			}			
		} 
		[aFileManager release];
				
		// Add navigation controller with our root view controller.
		RootViewController *aRootViewController = [[RootViewController alloc] init]; 
		UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:aRootViewController];
		[aRootViewController release];
		[aNavigationController setNavigationBarHidden:YES animated:NO];
		aNavigationController.toolbarHidden = YES;
		self.window.rootViewController = aNavigationController;
		[aNavigationController release];
		
		/*
		 // Add root view controller.
		UIViewController *aRootViewController = [[RootViewController alloc] init];
		self.window.rootViewController = aRootViewController;
		[aRootViewController release];
		 */
	}
	
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Text_Memory" withExtension:@"momd"];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return managedObjectModel_;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
	// If the main store doesn't exist, and we're not making the default-data store, then copy the default data to the main store.
	
	NSURL *mainStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:mainStoreName];
	NSString *mainStorePath = [mainStoreURL path];
	NSFileManager *aFileManager = [[NSFileManager alloc] init];
	BOOL copyDefaultData = NO;
	if (![aFileManager fileExistsAtPath:mainStorePath] && !makeDefaultDataStore) {
		
		copyDefaultData = YES;
	} 
	[aFileManager release];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:mainStoreURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
	
	if (copyDefaultData) {
		
		NSLog(@"Copying default data to main store.");
		[DefaultData copyToMainStore];
	}
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    
	// Could use [NSFileManager defaultManager], but docs say it's not thread safe?
	NSFileManager *aFileManager = [[NSFileManager alloc] init];
	NSArray *urlArray = [aFileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	[aFileManager release];
	NSURL *aURL = (NSURL *)[urlArray objectAtIndex:0];

	return aURL;
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    
    [managedObjectContext_ release];
    [managedObjectModel_ release];
    [persistentStoreCoordinator_ release];
    
    [window release];
    [super dealloc];
}

- (void)saveContext {
    
    NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

+ (NSNumber *)versionNumber {
	
	NSString *versionNumberString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSNumberFormatter *aNumberFormatter = [[NSNumberFormatter alloc] init];
	[aNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	NSNumber *aVersionNumber = [aNumberFormatter numberFromString:versionNumberString];
	[aNumberFormatter release];
    
	return aVersionNumber;
}

@end

