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
#import "QTree.h"
@class SOListViewController;
@class ViewController;
@import MapKit;

@interface SOMapViewDelegate : NSObject<MKMapViewDelegate, KPClusteringControllerDelegate>

@property (strong, nonatomic) KPClusteringController* clusteringController;
@property (weak, nonatomic) MKMapView *mapView;
@property (assign, nonatomic) double latitudeDelta;
@property (strong, nonatomic) SOListViewController *listViewVC;
@property (weak, nonatomic) ViewController *delegate;
@property (strong, nonatomic) QTree *tree;

-(instancetype)initWithMapView:(MKMapView *)mapView;
- (void)mapView:(MKMapView *)mapView regionIsChanging:(BOOL)animated;

@end
