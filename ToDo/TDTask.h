//
//  TDTask.h
//  ToDo
//
//  Created by Maciej Lobodzinski on 01.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface TDTask : NSManagedObject

@property NSString *text;
@property NSDate *completedAt;

@property (nonatomic, getter = isCompleted) BOOL completed;

@end
