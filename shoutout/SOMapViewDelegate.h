//
//  SOMapViewDelegate.h
//  shoutout
//
//  Created by Mayank Jain on 9/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKMapView+ZoomLevel.h"
#import "SOAnnotation.h"
#import "ShoutRMMarker.h"
#import "ShoutClusterMarker.h"
@import MapKit;

@interface SOMapViewDelegate : NSObject<MKMapViewDelegate, KPClusteringControllerDelegate>

@property (strong, nonatomic) KPClusteringController* clusteringController;
@property (strong, nonatomic) MKMapView *mapView;
@property (assign, nonatomic) double latitudeDelta;

-(instancetype)initWithMapView:(MKMapView *)mapView;

@end
