//
//  TDLoginViewController.m
//  ToDo
//
//  Created by Maciej Lobodzinski on 03.12.2012.
//  Copyright (c) 2012 Maciej Lobodzinski. All rights reserved.
//

#import "TDLoginViewController.h"
#import "TDTasksViewController.h"

@interface TDLoginViewController ()

@end

@implementation TDLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"123");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadNewController:(id)sender {
    [self performSegueWithIdentifier:@"goToTasks" sender:sender];
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    TDTasksViewController *tasksVC = [storyboard instantiateViewControllerWithIdentifier:@"TDTasksViewController"];
    tasksVC.managedObjectContext = self.managedObjectContext;
    
    UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:identifier source:self destination:tasksVC];
    [self prepareForSegue:segue sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"goToTasks"]) {
        //[segue.destinationViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
        [self presentModalViewController:segue.destinationViewController animated:NO];
    }
}

@end
