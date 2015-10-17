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

    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundLayer = [CALayer layer];
        self.backgroundLayer.name = @"profile";
        self.backgroundLayer.frame = CGRectMake(0.0f, 0.0f, 56.0f, 67.0f);
        self.backgroundLayer.contents = (id)[UIImage imageNamed:imageToUse].CGImage;
        self.backgroundLayer.masksToBounds = YES;
        [self.layer addSublayer:self.backgroundLayer];
        
        CALayer *circleLayer = [CALayer layer];
        circleLayer.frame = CGRectMake(2.5f, 2.5f, 51.0f, 51.0f);
        circleLayer.cornerRadius = 25.0f;
        circleLayer.backgroundColor = [UIColor whiteColor].CGColor;
        [self.layer addSublayer:circleLayer];
        
        self.textLayer = [[CATextLayer alloc] init];
        self.textLayer.frame = CGRectMake(3.0f, 10.0f, 50.5f, 50.5f);
        self.textLayer.string = annotation.title;
        self.textLayer.fontSize = 24.0f;
        self.textLayer.wrapped = YES;
        [self.textLayer setAlignmentMode:@"center"];
        self.textLayer.contentsScale = [[UIScreen mainScreen] scale];
        self.textLayer.foregroundColor = [UIColor blackColor].CGColor;
        [self.layer addSublayer:self.textLayer];
        
        NSLog(@"created pin");
        self.frame = self.backgroundLayer.bounds;
        self.centerOffset = CGPointMake(self.frame.size.width/2.0, -self.frame.size.height/2.0);
    }
    return self;
}

- (void) setTitle:(NSString *)title{
    _title = title;
    self.textLayer.string = title;
}

@end
