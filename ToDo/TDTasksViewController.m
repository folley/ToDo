//
//  TDTasksViewController.m
//  ToDo
//
//  Created by Maciej Lobodzinski on 01.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import "TDTasksViewController.h"
#import "TDTask.h"

@interface TDTasksViewController () <NSFetchedResultsControllerDelegate>
@property NSFetchedResultsController *fetchedResultsController;
@end

@implementation TDTasksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ToDo";
    
    
    /*
     Update Error: Error Domain=AFNetworkingErrorDomain Code=-1011 "Expected status code in (200-299), got 406" UserInfo=0x837de80 {NSLocalizedRecoverySuggestion={"errors":{}}, AFNetworkingOperationFailingURLRequestErrorKey=<NSMutableURLRequest http://afternoon-wildwood-9932.herokuapp.com/tasks/86>, NSErrorFailingURLKey=http://afternoon-wildwood-9932.herokuapp.com/tasks/86, NSLocalizedDescription=Expected status code in (200-299), got 406, AFNetworkingOperationFailingURLResponseErrorKey=<NSHTTPURLResponse: 0x813f7d0>}
     */
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Task"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"completedAt" ascending:YES]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
}

#pragma mark - Table View

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@""]) {
        cell.textLabel.text = @"BAZINGA";
    }
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    TDTask *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = task.text;
    cell.textLabel.textColor = [task isCompleted] ? [UIColor lightGrayColor] : [UIColor blackColor];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", task.text];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.managedObjectContext performBlock:^{
        TDTask *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
        if (task.completed) {
            [self.managedObjectContext deleteObject:task];
            [self.managedObjectContext save:nil];
            NSLog(@"task DELETED");
        }
        if (!task.completed) {
            task.completed = !task.completed;
            [self.managedObjectContext save:nil];
            NSLog(@"task COMPLETED");
        }
    }];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)object
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]     withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] forRowAtIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]    withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]     withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = [textField.text copy];
    textField.text = nil;
    [textField resignFirstResponder];
    
    [self.managedObjectContext performBlock:^{
        NSManagedObject *managedObject = [NSEntityDescription
                                          insertNewObjectForEntityForName:@"Task"
                                          inManagedObjectContext:self.managedObjectContext];
        
        if ([text isEqualToString:@""]) {
            //[self.tableView reloadData];
             [managedObject setValue:@"BAZINGA" forKey:@"text"];
        }
        else {
            [managedObject setValue:text forKey:@"text"];
        }
        NSLog(@"task DODANY");
        [self.managedObjectContext save:nil];
    }];
    return YES;
}

@end
