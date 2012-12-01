//
//  TDAppDelegate.h
//  ToDo
//
//  Created by Maciej Lobodzinski on 01.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ToDoIncrementalStore.h"

@interface TDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

@property (strong, nonatomic) UINavigationController *navigationController;

@end
