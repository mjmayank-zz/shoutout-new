//
//  ShoutRMMarker.h
//  Thoughts
//
//  Created by Zak Avila on 5/10/14.
//  Copyright (c) 2014 Mayank Jain. All rights reserved.
//

//#import "ButtonRMMarker.h"
#import "SOAnnotation.h"
#import "kingpin.h"
#import "SOMarkerSubView.h"
#import "PNChart.h"
#import "UIImage+ColorMask.h"
#import "UIColor+Hex.h"
@import MapKit;

@class SOPinBusinessViewController;
@class ShoutRMMarker;
@class RMAnnotation;

@protocol ShoutRMMarker <NSObject>
- (void)shoutRMMarker:(ShoutRMMarker*)marker didPressButtonWithName:(NSString*)buttonName;
@end

@interface ShoutRMMarker : MKAnnotationView

@property (nonatomic, strong) NSString *shout;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) SOPinBusinessViewController *businessSubVC;

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation
                   reuseIdentifier:(NSString *)reuseIdentifier
                    image:(UIImage *)image;
- (void)didPressButtonWithName:(NSString*)name;
- (void)scaleForZoomLevel:(double)zoomLevel;
- (void)showShout;
- (void)hideShout;
- (void)setOnline:(BOOL)online;
- (void)sendMessage;

@end