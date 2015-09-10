//
//  SOAnnotation.h
//  shoutout
//
//  Created by Mayank Jain on 9/3/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapbox/Mapbox.h>
@import MapKit;

@interface SOAnnotation : NSObject<MKAnnotation>

@property (strong, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *profileImage;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

-(id)initWithTitle:(NSString *)title Subtitle:(NSString *)subtitle Location:(CLLocationCoordinate2D)coordinate;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end
