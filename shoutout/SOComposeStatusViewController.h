//
//  SOComposeStatusViewController.h
//  shoutout
//
//  Created by Mayank Jain on 11/8/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <Firebase/Firebase.h>

@interface SOComposeStatusViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UITextView *statusTextView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UILabel *statusCharacterCount;

@property (strong, nonatomic) Firebase* shoutoutRootStatus;

@end
