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
@class SOListViewController;
@import MapKit;

@interface SOMapViewDelegate : NSObject<MKMapViewDelegate, KPClusteringControllerDelegate>

@property (strong, nonatomic) KPClusteringController* clusteringController;
@property (weak, nonatomic) MKMapView *mapView;
@property (assign, nonatomic) double latitudeDelta;
@property (strong, nonatomic) SOListViewController *listViewVC;

-(instancetype)initWithMapView:(MKMapView *)mapView;
- (void)mapView:(MKMapView *)mapView regionIsChanging:(BOOL)animated;

@end
