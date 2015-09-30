//
//  ShoutRMMarker.m
//  Thoughts
//
//  Created by Zak Avila on 5/10/14.
//  Copyright (c) 2014 Mayank Jain. All rights reserved.
//

#import "ShoutRMMarker.h"

@interface ShoutRMMarker ()

@end

#define ANCHOR_POINT_X 0.0f
#define ANCHOR_POINT_Y 0.5f

@implementation ShoutRMMarker

-(instancetype)init{
    if (self = [super init]) {
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"SOPinView" owner:self options:nil];
        self = [subviewArray objectAtIndex:0];
    }
    return self;
}

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation
                   reuseIdentifier:(NSString *)reuseIdentifier image:(UIImage *)image{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:@"SOPinView" owner:self options:nil];
        self = [subviewArray objectAtIndex:0];
        self.profileImageView.layer.cornerRadius = 30.0f;
        self.profileImageView.layer.masksToBounds = YES;
        if (annotation.title)
            self.shout = [[NSString alloc] initWithString:((SOAnnotation*)annotation).subtitle];

        self.usernameLabel.text = annotation.title;
        
        NSLog(@"created pin");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapDidScale:) name:
         @"mapDidScale" object:nil];
        
        [self scaleByPercentage:0.5];
        self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
    }
    return self;
}

- (void)didPressButtonWithName:(NSString *)name
{
    if ([name isEqualToString:@"profile"]) {
        if (self.shout)
            [self toggleShout];
        else
            [self toggleIcons];
    }
    else if ([name isEqualToString:@"email"]) {
        
    }
    else if ([name isEqualToString:@"share"]) {
        
    }
    else if ([name isEqualToString:@"location"]) {
        
    }
    else if ([name isEqualToString:@"friend"]) {
        
    }
    else if ([name isEqualToString:@"ellipses"]) {
        [self toggleShout];
    }
    else if ([name isEqualToString:@"farEllipses"]) {
        [self showIconsWithShout];
    }
    else if ([name isEqualToString:@"verticalEllipses"]) {
        [self hideIconsWithShout];
    }
}

- (void)changeStatus:(NSString *)status{
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
    }
    self.shoutLabel.text = status;
}

- (void)toggleShout
{
    if (self.bubbleContainerView.hidden)
        [self showShout];
    else
        [self hideShout];
}

-(void)mapDidScale:(NSNotification *)notification{
//    [self scaleByPercentage:0.5];
//    self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
}

- (void)scaleByPercentage:(double)scale{
    self.transform = CGAffineTransformMakeScale(scale, scale);
}

- (void)setProfileImage:(UIImage *)profileImage{
    _profileImage = profileImage;
    _profileImageView.image = profileImage;
}

- (void)showShout
{
    [self.bubbleContainerView setHidden:NO];
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
    }
    [self changeStatus:annotation.subtitle];
}

- (void)hideShout
{
    [self.bubbleContainerView setHidden:YES];
}

- (void)toggleIcons
{
//    if (self.shout && self.imageLayer.frame.origin.y == 30.0f)
//        [self hideIconsWithShout];
//    else if (self.shout)
//        [self showIconsWithShout];
//    else if (!self.shout && self.imageLayer.frame.origin.y == 15.0f)
//        [self hideIconsWithoutShout];
//    else if (!self.shout)
//        [self showIconsWithoutShout];
}

- (void)showIconsWithShout
{
//    [self replaceUIImage:[UIImage imageNamed:@"shoutBubbleAll"] rect:CGRectMake(0.0f, 0.0f, 194.5f, 94.0f)];
//    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 30.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
//    self.farVerticalEllipses.hidden = NO;
//    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 30.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
}

- (void)hideIconsWithShout
{
//    [self replaceUIImage:[UIImage imageNamed:@"shoutBubbleText"] rect:CGRectMake(0.0f, 0.0f, 164.0f, 67.0f)];
//    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 3.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
//    self.farVerticalEllipses.hidden = YES;
//    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 3.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
}

- (void)showIconsWithoutShout
{
//    [super replaceUIImage:[UIImage imageNamed:@"ShoutBubbleIcons"] anchorPoint:CGPointMake(ANCHOR_POINT_X, ANCHOR_POINT_Y)];
//    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 15.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
//    self.emailLayer.hidden = NO;
//    self.locationLayer.hidden = NO;
//    self.friendLayer.hidden = NO;
}

- (void)hideIconsWithoutShout
{
//    [super replaceUIImage:[UIImage imageNamed:@"ShoutBubble"] anchorPoint:CGPointMake(ANCHOR_POINT_X, ANCHOR_POINT_Y)];
//    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 3.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
//    self.emailLayer.hidden = YES;
//    self.locationLayer.hidden = YES;
//    self.friendLayer.hidden = YES;
}

@end
