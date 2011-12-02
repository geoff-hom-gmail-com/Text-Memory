//
//  DefaultData.h
//  Text Memory
//
//  Currently, the only instance variable here is the version number. The actual default data is all Texts.
//
//  Created by Geoffrey Hom on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Name of the file for the default-data Core Data store.
extern NSString *defaultDataStoreName;

// Title of the text to show when the app is first started.
extern NSString *welcomeTextTitle;

@interface DefaultData : NSManagedObject {
}

// The app version when the default data was last updated in the main store.
@property (nonatomic, retain) NSNumber *versionNumber;

// Check the current app version vs the version when the default data was last updated in the main store. If the current version is greater, then update the default data.
+ (void)checkMainStore;

// Copy the default data from the default-data store to the main store. Assumes main store may be empty.
+ (void)copyToMainStore;

/* 
 (For developers.) Make the Core Data store for default data by parsing a property list. 
 
 When the user first runs an app, how do we initialize the main store with default data? From the user's perspective, copying a pre-made store is best because it's fastest (c.f., parsing a property list). So, prior to releasing/updating the app, the developer should use this method to create the pre-made store.
 
 Once the default-data store has been made, it needs to be added to the main bundle (in Xcode, do Add -> Existing Files...). The store can be found in the app's Documents directory. This method should output the path to the console; for example, "~user/Library/Application Support/iPhone Simulator/ver/Applications/longIDnumber/Documents/x.sqlite." (I could automatically add it to the main bundle since this would be run in the simulator, but it might break in future releases?)
 
 If the default data ever changes, use this method and then replace the previous default-data store in the main bundle. Note that the main store will be initialized with default data only if the main store doesn't exist yet. So, you may have to delete the main store to check.
 */
+ (void)makeStore;

// Restore the default data in the main store without affecting the user's data.
+ (void)restore;

@end
