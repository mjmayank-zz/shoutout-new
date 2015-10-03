//
//  SOMarkerSubView.h
//  shoutout
//
//  Created by Mayank Jain on 10/3/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SOMarkerSubView : UIView

@property (nonatomic, strong) NSString *shout;
@property (nonatomic, strong) UIImage *profileImage;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UILabel *shoutLabel;
@property (strong, nonatomic) IBOutlet UIView *bubbleContainerView;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@end
