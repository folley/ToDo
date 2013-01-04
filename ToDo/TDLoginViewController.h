//
//  TDLoginViewController.h
//  ToDo
//
//  Created by Maciej Lobodzinski on 03.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDLoginViewController : UIViewController

@property NSManagedObjectContext *managedObjectContext;
@property IBOutlet UITextField *loginTF;
@property IBOutlet UITextField *passwordTF;

- (void)loadNewController:(id)sender;

@end
