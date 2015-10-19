//
//  SOComposeStatusView.h
//  shoutout
//
//  Created by Mayank Jain on 10/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
@class ViewController;

@interface SOComposeStatusView : UIView

@property (strong, nonatomic) IBOutlet UILabel *statusCharacterCount;
@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UITextView *statusTextView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelStatusButton;
@property (strong, nonatomic) IBOutlet UIView *profilePictureBorder;

@property (weak, nonatomic) ViewController* delegate;

@end
