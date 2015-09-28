//
//  ShoutRMMarker.m
//  Thoughts
//
//  Created by Zak Avila on 5/10/14.
//  Copyright (c) 2014 Mayank Jain. All rights reserved.
//

#import "ShoutRMMarker.h"

@interface ShoutRMMarker ()
@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) CALayer *imageLayer;
@property (nonatomic, strong) CATextLayer *textLayer;
@property (nonatomic, strong) CALayer *emailLayer;
@property (nonatomic, strong) CALayer *locationLayer;
@property (nonatomic, strong) CALayer *friendLayer;
@property (nonatomic, strong) CALayer *ellipsesLayer;
@property (nonatomic, strong) CALayer *farEllipsesLayer;
@property (nonatomic, strong) CALayer *farEmailLayer;
@property (nonatomic, strong) CALayer *farShareLayer;
@property (nonatomic, strong) CALayer *farLocationLayer;
@property (nonatomic, strong) CALayer *farFriendLayer;
@property (nonatomic, strong) CALayer *farVerticalEllipses;
@property (nonatomic, strong) CALayer *onlineIndicator;
@property (nonatomic, strong) UIImageView *profileImageView;
@end

#define ANCHOR_POINT_X 0.0f
#define ANCHOR_POINT_Y 0.5f

@implementation ShoutRMMarker

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation
                   reuseIdentifier:(NSString *)reuseIdentifier image:(UIImage *)image{
    NSString *imageToUse = @"shoutBubbleMore";
    if (annotation.title) {
        imageToUse = @"shoutBubble";
    }
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        if (annotation.title)
            self.shout = [[NSString alloc] initWithString:((SOAnnotation*)annotation).subtitle];
        
        self.backgroundLayer = [CALayer layer];
        self.backgroundLayer.name = @"profile";
        UIImage *backgroundImage = [UIImage imageNamed:imageToUse];
        self.backgroundLayer.contents = (id)backgroundImage.CGImage;
        self.backgroundLayer.frame = CGRectMake(0.0f, 0.0f, backgroundImage.size.width/2.0, backgroundImage.size.height/2.0);
        self.backgroundLayer.masksToBounds = YES;
        [self.layer addSublayer:self.backgroundLayer];
        
        self.profileImageView = [[UIImageView alloc] initWithImage:image];
        self.profileImageView.frame = CGRectMake(3.0f, 3.0f, 50.5f, 50.5f);
        self.profileImageView.layer.cornerRadius = 25.0f;
        self.profileImageView.layer.masksToBounds = YES;
        [self addSubview:self.profileImageView];
        
        self.textLayer = [[CATextLayer alloc] init];
        self.textLayer.frame = CGRectMake(58.0f, 3.0f, 72.0f, 50.0f);
        self.textLayer.fontSize = 12.6f;
        self.textLayer.wrapped = YES;
        self.textLayer.contentsScale = [[UIScreen mainScreen] scale];
        self.textLayer.foregroundColor = [UIColor blackColor].CGColor;
        self.textLayer.hidden = YES;
        [self.layer addSublayer:self.textLayer];
        [self changeStatus:self.shout];
        
//        self.emailLayer = [CALayer layer];
//        self.emailLayer.name = @"email";
//        self.emailLayer.frame = CGRectMake(50.5f, 0.0f, 25.0f, 25.0f);
//        self.emailLayer.hidden = YES;
//        [self.layer addSublayer:self.emailLayer];
//        
//        self.locationLayer = [CALayer layer];
//        self.locationLayer.name = @"location";
//        self.locationLayer.frame = CGRectMake(60.0f, 27.0f, 25.0f, 25.0f);
//        self.locationLayer.hidden = YES;
//        [self.layer addSublayer:self.locationLayer];
//        
//        self.friendLayer = [CALayer layer];
//        self.friendLayer.name = @"friend";
//        self.friendLayer.frame = CGRectMake(50.5f, 55.0f, 25.0f, 25.0f);
//        self.friendLayer.hidden = YES;
//        [self.layer addSublayer:self.friendLayer];
//        
        self.ellipsesLayer = [CALayer layer];
        self.ellipsesLayer.name = @"ellipses";
        self.ellipsesLayer.frame = CGRectMake(50.0f, 1.5f, 25.0f, 25.0f);
        self.ellipsesLayer.hidden = YES;
        [self.layer addSublayer:self.ellipsesLayer];

        self.farEllipsesLayer = [CALayer layer];
        self.farEllipsesLayer.name = @"farEllipses";
        self.farEllipsesLayer.frame = CGRectMake(138.0f, 1.5f, 25.0f, 25.0f);
        self.farEllipsesLayer.hidden = YES;
        [self.layer addSublayer:self.farEllipsesLayer];
//
//        self.farEmailLayer = [CALayer layer];
//        self.farEmailLayer.name = @"email";
//        self.farEmailLayer.frame = CGRectMake(125.0f, 0.0f, 25.0f, 25.0f);
//        self.farEmailLayer.hidden = YES;
//        [self.layer addSublayer:self.farEmailLayer];
//        
//        self.farShareLayer = [CALayer layer];
//        self.farShareLayer.name = @"share";
//        self.farShareLayer.frame = CGRectMake(155.0f, 0.0f, 25.0f, 25.0f);
//        self.farShareLayer.hidden = YES;
//        [self.layer addSublayer:self.farShareLayer];
//        
//        self.farLocationLayer = [CALayer layer];
//        self.farLocationLayer.name = @"location";
//        self.farLocationLayer.frame = CGRectMake(168.0f, 30.0f, 25.0f, 25.0f);
//        self.farLocationLayer.hidden = YES;
//        [self.layer addSublayer:self.farLocationLayer];
//        
//        self.farFriendLayer = [CALayer layer];
//        self.farFriendLayer.name = @"friend";
//        self.farFriendLayer.frame = CGRectMake(152.0f, 57.0f, 25.0f, 25.0f);
//        self.farFriendLayer.hidden = YES;
//        [self.layer addSublayer:self.farFriendLayer];
//        
        self.farVerticalEllipses = [CALayer layer];
        self.farVerticalEllipses.name = @"verticalEllipses";
        self.farVerticalEllipses.frame = CGRectMake(137.0f, 29.0f, 25.0f, 25.0f);
        self.farVerticalEllipses.hidden = YES;
        [self.layer addSublayer:self.farVerticalEllipses];

        self.onlineIndicator = [CALayer layer];
        self.onlineIndicator.name = @"onlineIndicator";
        self.onlineIndicator.frame = CGRectMake(50.0f, 0.0f, 10.0f, 10.0f);
        self.onlineIndicator.cornerRadius = 5.0f;
        self.onlineIndicator.backgroundColor = [UIColor greenColor].CGColor;
        self.onlineIndicator.hidden = YES;
        [self.layer addSublayer:self.onlineIndicator];
        
        NSLog(@"created pin");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapDidScale:) name:
         @"mapDidScale" object:nil];
        
        self.frame = CGRectMake(0.0f, 0.0f, backgroundImage.size.width/2.0, backgroundImage.size.height/2.0);
        self.centerOffset = CGPointMake(backgroundImage.size.width/4.0, -backgroundImage.size.height/4.0);
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
    NSString *newStatus = [NSString stringWithFormat:@"%@; %@", self.annotation.title, status];
    self.textLayer.string = newStatus;
}

- (void)toggleShout
{
    if (self.farEllipsesLayer.hidden)
        [self showShout];
    else
        [self hideShout];
}

-(void)mapDidScale:(NSNotification *)notification{
    [self scaleByPercentage:0.9];
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
    UIImage *image = [UIImage imageNamed:@"shoutBubbleText"];
    [self replaceUIImage:image rect:CGRectMake(0.0f, 0.0f, 164.0f, 67.0f)];
    self.farEllipsesLayer.hidden = NO;
    self.farVerticalEllipses.hidden = YES;
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
    }
    [self changeStatus:annotation.subtitle];
    self.textLayer.hidden = NO;
    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 3.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
}

- (void)hideShout
{
    UIImage *image = [UIImage imageNamed:@"shoutBubble"];
    [self replaceUIImage:image rect:CGRectMake(0.0f, 0.0f, image.size.width/2.0, image.size.height/2.0)];
    self.farEllipsesLayer.hidden = YES;
    self.farVerticalEllipses.hidden = YES;
    self.textLayer.hidden = YES;
    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 3.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
}

- (void)toggleIcons
{
    if (self.shout && self.imageLayer.frame.origin.y == 30.0f)
        [self hideIconsWithShout];
    else if (self.shout)
        [self showIconsWithShout];
    else if (!self.shout && self.imageLayer.frame.origin.y == 15.0f)
        [self hideIconsWithoutShout];
    else if (!self.shout)
        [self showIconsWithoutShout];
}

- (void)replaceUIImage:(UIImage *)image rect:(CGRect)rect{
    [self.backgroundLayer removeFromSuperlayer];
    self.backgroundLayer = [CALayer layer];
    self.backgroundLayer.name = @"profile";
    self.backgroundLayer.frame = rect;
    self.backgroundLayer.contents = (id)image.CGImage;
    self.backgroundLayer.masksToBounds = YES;
    [self.layer insertSublayer:self.backgroundLayer atIndex:0];
}

- (void)showIconsWithShout
{
    [self replaceUIImage:[UIImage imageNamed:@"shoutBubbleAll"] rect:CGRectMake(0.0f, 0.0f, 194.5f, 94.0f)];
    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 30.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
    self.farVerticalEllipses.hidden = NO;
    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 30.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
}

- (void)hideIconsWithShout
{
    [self replaceUIImage:[UIImage imageNamed:@"shoutBubbleText"] rect:CGRectMake(0.0f, 0.0f, 164.0f, 67.0f)];
    self.imageLayer.frame = CGRectMake(self.imageLayer.frame.origin.x, 3.0f, self.imageLayer.frame.size.width, self.imageLayer.frame.size.height);
    self.farVerticalEllipses.hidden = YES;
    self.textLayer.frame = CGRectMake(self.textLayer.frame.origin.x, 3.0f, self.textLayer.frame.size.width, self.textLayer.frame.size.height);
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
