//
//  TDTasksViewController.h
//  ToDo
//
//  Created by Maciej Lobodzinski on 01.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDTasksViewController : UITableViewController <UITextFieldDelegate>

@property NSManagedObjectContext *managedObjectContext;
@property IBOutlet UITextField *taskTextField;
@property BOOL isKeyboardOnTheScreen;

@end
