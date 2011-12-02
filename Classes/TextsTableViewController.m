//
//  TextsTableViewController.m
//  Text Memory
//
//  Created by Geoffrey Hom on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultData.h"
#import "Text.h"
#import "TextMemoryAppDelegate.h"
#import "TextsTableViewController.h"

// Private category for private methods.
@interface TextsTableViewController ()

// Texts to show in table view.
@property (nonatomic, retain) NSArray *textsArray;

@end

@implementation TextsTableViewController

@synthesize currentText, delegate;
@synthesize textsArray;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    //self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
		
	// Fetch all texts.
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init]; 
	
	// Set entity.
	TextMemoryAppDelegate *aTextMemoryAppDelegate = [[UIApplication sharedApplication] delegate];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Text" inManagedObjectContext:aTextMemoryAppDelegate.managedObjectContext]; 
	[request setEntity:entity];
	
	// Set sorting: alphabetize by whether default data, then by title.
	NSSortDescriptor *byDefaultDataSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isDefaultData_" ascending:NO];
	NSSortDescriptor *byTitleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:byDefaultDataSortDescriptor, byTitleSortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	// Fetch.
	NSError *error; 
	NSMutableArray *fetchResultsMutableArray = [[aTextMemoryAppDelegate.managedObjectContext executeFetchRequest:request error:&error] mutableCopy]; 
	
	[request release];
	
	if (fetchResultsMutableArray == nil) {
		
		// Handle the error.
		NSLog(@"Fetch result was nil.");
	}
	
	// Move instructions to the top of the table.
	int instructionsIndex = -1;
	for (int i=0; i < fetchResultsMutableArray.count; i++) {
		
		Text *aText = [fetchResultsMutableArray objectAtIndex:i];
		if ([aText isDefaultData] && [aText.title isEqualToString:welcomeTextTitle]) {
			instructionsIndex = i;
			break;
		}
	}
	if (instructionsIndex != -1) {
		
		Text *instructionsText = [fetchResultsMutableArray objectAtIndex:instructionsIndex];
		[fetchResultsMutableArray removeObjectAtIndex:instructionsIndex];
		[fetchResultsMutableArray insertObject:instructionsText atIndex:0];
	}
	
	self.textsArray = fetchResultsMutableArray;
	
	// Set size in popover to match the number of content rows.
	[self.tableView layoutIfNeeded];
	CGSize size = CGSizeMake(320.0, self.tableView.contentSize.height);
	self.contentSizeForViewInPopover = size;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 0;
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
	// Return the number of rows in the section.
    return self.textsArray.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        //cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
	Text *aText = (Text *)[self.textsArray objectAtIndex:indexPath.row];
	cell.textLabel.text = aText.title;
	cell.detailTextLabel.text = aText.text;
	
	// If cell is for the current text, add a checkmark.
	if (aText == self.currentText) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    */
	
	self.currentText = [self.textsArray objectAtIndex:indexPath.row];
	
	// Notify the delegate that a text was selected.
	[self.delegate textsTableViewControllerDidSelectText:self];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	
	[currentText release];
	[textsArray release];
	
    [super dealloc];
}

@end

