//
//  ShoutClusterMarker.m
//  shoutout
//
//  Created by Mayank Jain on 9/13/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import "ShoutClusterMarker.h"

@interface ShoutClusterMarker ()
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
@property (nonatomic, strong) UIImageView *profileImageView;
@end

@implementation ShoutClusterMarker

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation
                   reuseIdentifier:(NSString *)reuseIdentifier{
    NSString *imageToUse = @"pinBubble";
//    if (annotation.title) {
//        imageToUse = @"shoutBubbleMore";
//    }
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundLayer = [CALayer layer];
        self.backgroundLayer.name = @"profile";
        self.backgroundLayer.frame = CGRectMake(0.0f, 0.0f, 56.0f, 67.0f);
        self.backgroundLayer.contents = (id)[UIImage imageNamed:imageToUse].CGImage;
        self.backgroundLayer.masksToBounds = YES;
        [self.layer addSublayer:self.backgroundLayer];
        
        self.textLayer = [[CATextLayer alloc] init];
        self.textLayer.frame = CGRectMake(20.0f, 10.0f, 30.0f, 50.0f);
        self.textLayer.string = annotation.title;
        self.textLayer.fontSize = 24.0f;
        self.textLayer.wrapped = YES;
        self.textLayer.contentsScale = [[UIScreen mainScreen] scale];
        self.textLayer.foregroundColor = [UIColor blackColor].CGColor;
        [self.layer addSublayer:self.textLayer];
        
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
//        self.ellipsesLayer = [CALayer layer];
//        self.ellipsesLayer.name = @"ellipses";
//        self.ellipsesLayer.frame = CGRectMake(50.0f, 1.5f, 25.0f, 25.0f);
//        self.ellipsesLayer.hidden = YES;
//        [self.layer addSublayer:self.ellipsesLayer];
//        
//        self.farEllipsesLayer = [CALayer layer];
//        self.farEllipsesLayer.name = @"farEllipses";
//        self.farEllipsesLayer.frame = CGRectMake(138.0f, 1.5f, 25.0f, 25.0f);
//        self.farEllipsesLayer.hidden = YES;
//        [self.layer addSublayer:self.farEllipsesLayer];
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
//        self.farVerticalEllipses = [CALayer layer];
//        self.farVerticalEllipses.name = @"verticalEllipses";
//        self.farVerticalEllipses.frame = CGRectMake(137.0f, 29.0f, 25.0f, 25.0f);
//        self.farVerticalEllipses.hidden = YES;
//        [self.layer addSublayer:self.farVerticalEllipses];
        
        NSLog(@"created pin");
    }
    return self;
}

- (void) setTitle:(NSString *)title{
    _title = title;
    self.textLayer.string = title;
}

@end
