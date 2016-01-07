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
        self.subview = [[[NSBundle mainBundle] loadNibNamed:@"SOPinView" owner:self options:nil] firstObject];
        [self addSubview:self.subview];
        self.subview.profileImageView.layer.cornerRadius = self.subview.profileImageView.frame.size.height/2.0;
        self.subview.onlineIndicator.layer.cornerRadius = self.subview.onlineIndicator.frame.size.height/2.0;
        self.subview.profileImageView.layer.masksToBounds = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapDidScale:) name:
         @"mapDidScale" object:nil];
        
        self.businessSubview = [[SOBusinessPinVew alloc] init];
        
        [self.subview.bubbleContainerView addSubview:self.businessSubview];
        
        self.frame = self.subview.pinView.frame;
        self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
    }
    return self;
}

-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"mapDidScale" object:nil];
}

- (void)didPressButtonWithName:(NSString *)name
{
    if ([name isEqualToString:@"profile"]) {
        [self toggleShout];
    }
}

- (void)toggleShout
{
    if (self.subview.bubbleContainerView.hidden)
        [self showShout];
    else
        [self hideShout];
}

-(void)mapDidScale:(NSNotification *)notification{
    double zoomLevel = [notification.userInfo[@"zoomLevel"] doubleValue];
    [self scaleForZoomLevel:zoomLevel];
//    self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
}

- (void)scaleForZoomLevel:(double)zoomLevel{
    double scale = ((zoomLevel-14) * 20) / 100.0;
    if(scale < 0.2){
        scale = 0.2;
    }
    self.scale = scale;
    double factor = 1;
    if (!self.subview.bubbleContainerView.hidden) {
        factor = 1.2;
    }
    self.transform = CGAffineTransformMakeScale(scale * factor, scale * factor);
    self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
}

- (void)setProfileImage:(UIImage *)profileImage{
    _profileImage = profileImage;
    self.subview.profileImageView.image = profileImage;
}

- (void)showShout{
    [self.subview.bubbleContainerView setHidden:NO];
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
    }
    self.subview.shoutLabel.text = annotation.subtitle;
    self.subview.usernameLabel.text = [NSString stringWithFormat:@"-%@", annotation.title];
    if(annotation.userInfo[@"updatedAt"]){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yy HH:mm"];
        NSString *dateString = [dateFormatter stringFromDate:annotation.userInfo[@"updatedAt"]];
        self.subview.timeLabel.text = dateString;
    }
    self.transform = CGAffineTransformMakeScale(self.scale * 1.2, self.scale * 1.2);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width * 3.0, self.frame.size.height);
    self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
}

- (void)hideShout{
    [self.subview.bubbleContainerView setHidden:YES];
    [self.subview.messageOverlayView setHidden:YES];
    self.transform = CGAffineTransformMakeScale(self.scale, self.scale);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width / 3.0, self.frame.size.height);
    self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
}

-(void)setOnline:(BOOL)online{
    self.subview.onlineIndicator.hidden = !online;
}

-(void)sendMessage{
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
        NSString * username = annotation.userInfo[@"username"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"replyToShout" object:self userInfo:@{@"username":username}];
    }
}

@end
