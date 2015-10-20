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
@import MapKit;

@class ShoutRMMarker;
@class RMAnnotation;

@protocol ShoutRMMarker <NSObject>
- (void)shoutRMMarker:(ShoutRMMarker*)marker didPressButtonWithName:(NSString*)buttonName;
@end

@interface ShoutRMMarker : MKAnnotationView

@property (nonatomic, strong) SOMarkerSubView *subview;
@property (nonatomic, strong) NSString *shout;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, assign) double scale;

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation
                   reuseIdentifier:(NSString *)reuseIdentifier
                    image:(UIImage *)image;
- (void)didPressButtonWithName:(NSString*)name;
- (void)scaleForZoomLevel:(double)zoomLevel;
- (void)showShout;
- (void)hideShout;
-(void)setOnline:(BOOL)online;

@end