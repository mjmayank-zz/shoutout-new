//
//  SOBlockMapViewController.m
//  shoutout
//
//  Created by Mayank Jain on 11/11/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOBlockMapViewController.h"

@implementation SOBlockMapViewController

-(void)viewDidLoad{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    if([[PFUser currentUser][@"visible"] boolValue]){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
