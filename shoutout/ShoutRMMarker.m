//
//  ShoutRMMarker.m
//  Thoughts
//
//  Created by Zak Avila on 5/10/14.
//  Copyright (c) 2014 Mayank Jain. All rights reserved.
//

#import "ShoutRMMarker.h"
#import "Shoutout-Swift.h"

@interface ShoutRMMarker ()

@property (nonatomic, strong) SOMarkerSubView *subview;
//@property (nonatomic, strong) Business
@property (nonatomic, assign) double scale;

@end

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
        self.frame = self.subview.frame;
        [self addSubview:self.subview];
        
        SOAnnotation *soannotation = ((SOAnnotation *)self.annotation);
        if(soannotation.isStatic){
            if(soannotation.userInfo[@"pinType"]){
                [self setupBusinessView:soannotation];
            }
            [self setPinColor:[UIColor colorWithCSS:@"00A79D"]];
        }
        else if (soannotation.pinColor){
            [self setPinColor:[UIColor colorWithCSS:soannotation.pinColor]];
        }
        else{
            [self setPinColor:[UIColor colorWithCSS:@"2ECEFF"]];
        }
        
        self.subview.profileImageView.layer.cornerRadius = self.subview.profileImageView.frame.size.height/2.0;
        self.subview.onlineIndicator.layer.cornerRadius = self.subview.onlineIndicator.frame.size.height/2.0;
        self.subview.profileImageView.layer.masksToBounds = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapDidScale:) name:
         @"mapDidScale" object:nil];
        
        [self resetCenterOffset];
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

- (void)setupBusinessView:(SOAnnotation *)soannotation{
    self.businessSubVC = [[SOPinBusinessViewController alloc] initWithNibName:@"SOPinBusinessViewController" bundle:[NSBundle mainBundle]];
    self.businessSubVC.annotation = (SOAnnotation *)self.annotation;
    self.businessSubVC.latitude =  [NSNumber numberWithDouble:soannotation.coordinate.latitude];
    self.businessSubVC.longitude = [NSNumber numberWithDouble:soannotation.coordinate.longitude];
    self.businessSubVC.view.frame = CGRectMake(2, 0, self.businessSubVC.view.frame.size.width, self.businessSubVC.view.frame.size.height);
    self.frame = CGRectMake(0, 0, self.frame.size.width, self.businessSubVC.view.frame.size.height-17 + self.frame.size.height);
    self.subview.frame = CGRectMake(0, self.businessSubVC.view.frame.size.height-17, self.subview.frame.size.width, self.subview.frame.size.height);
    [self insertSubview:self.businessSubVC.view atIndex:99];
//    [self.subview setNeedsDisplay];
//    [self setNeedsDisplay];
}

- (void)setPinColor:(UIColor *)color{
    UIImage *image = [UIImage imageNamed:@"pinWithShadowGrayscale.png" withColor:color];
    self.subview.pinView.image = image;
}

- (void)toggleShout{
    if (self.subview.bubbleContainerView.hidden)
        [self showShout];
    else
        [self hideShout];
}

- (void)resetCenterOffset{
    self.centerOffset = CGPointMake(self.frame.size.width * 41.0/310.0, -self.frame.size.height/2.0);
}

-(void)mapDidScale:(NSNotification *)notification{
    double zoomLevel = [notification.userInfo[@"zoomLevel"] doubleValue];
    [self scaleForZoomLevel:zoomLevel];
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
        if(scale * factor < .7){
            factor = .7/scale;
        }
    }
    self.transform = CGAffineTransformMakeScale(scale * factor, scale * factor);
    [self resetCenterOffset];
}

- (void)setProfileImage:(UIImage *)profileImage{
    _profileImage = profileImage;
    self.subview.profileImageView.image = profileImage;
}

- (void)showShout{
    SOAnnotation *annotation = ((SOAnnotation *)self.annotation);
    if([self.annotation isKindOfClass:[KPAnnotation class]]){
        annotation = [[((KPAnnotation *)self.annotation) annotations] anyObject];
    }
    self.subview.shoutLabel.text = annotation.subtitle;
    if ([annotation.subtitle isEqualToString:@""]) {
        self.subview.messageOverlayView.hidden = NO;
    }
    self.subview.usernameLabel.text = [NSString stringWithFormat:@"-%@", annotation.title];
    if(annotation.userInfo[@"updatedAt"]){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd hh:mm a"];
        NSString *dateString = [dateFormatter stringFromDate:annotation.userInfo[@"updatedAt"]];
        self.subview.timeLabel.text = dateString;
    }
    if(annotation.userInfo[@"pinType"] && [annotation.userInfo[@"pinType"] isEqual: @"bar"]){
        self.businessSubVC.latitude =  [NSNumber numberWithDouble:annotation.coordinate.latitude];
        self.businessSubVC.longitude = [NSNumber numberWithDouble:annotation.coordinate.longitude];
        [self.businessSubVC refreshData];
    }
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(fmax(self.scale * 1.2, 0.7), fmax(self.scale * 1.2, 0.7));
        [self resetCenterOffset];
    } completion:^(BOOL finished){
    }];
    
    if(self.businessSubVC){
        self.businessSubVC.annotation = (SOAnnotation *)annotation;
        [self.businessSubVC.view setHidden:NO];
        self.businessSubVC.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
        self.businessSubVC.view.layer.opacity = 0;
    }
    [self.subview.bubbleContainerView setHidden:NO];
    self.subview.bubbleContainerView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.subview.bubbleContainerView.layer.opacity = 0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.subview.bubbleContainerView.layer.opacity = 1;
        self.subview.bubbleContainerView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        if(self.businessSubVC){
            self.businessSubVC.view.layer.opacity = 1;
            self.businessSubVC.view.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.subview.bubbleContainerView.transform = CGAffineTransformIdentity;
            if(self.businessSubVC){
                self.businessSubVC.view.transform = CGAffineTransformIdentity;
            }
        } completion:^(BOOL finished){
            // if you want to do something once the animation finishes, put it here
        }];
    }];
}

- (void)hideShout{
    if(self.businessSubVC){
        [self.businessSubVC.view setHidden:YES];
    }
    [self.subview.bubbleContainerView setHidden:YES];
    [self.subview.messageOverlayView setHidden:YES];
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(self.scale, self.scale);
        [self resetCenterOffset];
    }];
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
