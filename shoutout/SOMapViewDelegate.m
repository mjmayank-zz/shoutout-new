//
//  SOMapViewDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 9/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOMapViewDelegate.h"
#import "ViewController.h"
#import "Shoutout-Swift.h"

@interface SOMapViewDelegate ()
@property (strong, nonatomic) CLLocation * screenCenter;
@end

@implementation SOMapViewDelegate

-(instancetype)initWithMapView:(MKMapView *)mapView{
    if (self = [super init])
    {
        self.mapView = mapView;
        
        self.latitudeDelta = mapView.region.span.latitudeDelta;
        self.clusteringController = [[KPClusteringController alloc] initWithMapView:mapView];
        self.clusteringController.delegate = self;
        
        self.tree = [QTree new];
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    //    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
//    [self.delegate allowMapLoad];
    [self.clusteringController refresh:YES];
    if (mapView.zoomLevel > 5 && self.screenCenter != nil && self.delegate.lastLoadedLocation != nil && [self shouldLoadNewPins]) {
        [self.delegate updateMapWithLocation:self.screenCenter.coordinate];
    }
}

- (BOOL)shouldLoadNewPins {
    CLLocationDistance distance = [self.screenCenter distanceFromLocation:self.delegate.lastLoadedLocation];
    return distance / 1000. > 50;
}

- (CLLocation*)coordinateToLocObject:(CLLocationCoordinate2D)coords {
    return [[CLLocation alloc] initWithLatitude:coords.latitude longitude:coords.longitude];
}

- (void)mapView:(MKMapView *)mapView regionIsChanging:(BOOL)animated{
    NSDictionary *userInfo = @{
                               @"zoomLevel" : @(mapView.zoomLevel)
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:@"mapDidScale" object:self userInfo:userInfo];
    
    NSSet *annotationSet = [mapView annotationsInMapRect:[mapView visibleMapRect]];
    NSArray *annotationArray = [annotationSet allObjects];
    
    if(self.listViewVC.open){
        [self.listViewVC updateAnnotationArray:annotationArray];
    }
    
    CLLocationCoordinate2D coordinate = mapView.centerCoordinate;
    self.screenCenter = [self coordinateToLocObject:coordinate];
    
    if([annotationArray count] > 0){
        
        if(self.listViewVC.open){
            CGPoint point = CGPointMake(self.mapView.bounds.size.width/2.0, self.mapView.bounds.size.height/2.0);
            coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
            self.screenCenter = [self coordinateToLocObject:coordinate];
        }
        
        if (self.mapIsClustered) {
            /* Looping through array of annotations currently on screen */
            KPAnnotation *toShow = [self findClosestAnnotationToPoint:annotationArray];
            
            if (toShow) {
                [mapView selectAnnotation:toShow animated:YES];
            }
        }
        else{
            /* Using Quadtree */
            SOAnnotation *test = [self.tree neighboursForLocation:coordinate limitCount:1][0];
            KPAnnotation *toShow = [self.clusteringController getClusterForAnnotation:test];
            if(![toShow isCluster]){
                [mapView selectAnnotation:toShow animated:YES];
            }
        }
    }
}

- (KPAnnotation *)findClosestAnnotationToPoint: (NSArray *)annotationArray{
    KPAnnotation * toShow;
    
    CLLocationDistance minDistance = DBL_MAX;
    
    for(int i = 0; i<[annotationArray count]; i++){
        KPAnnotation * annotation = annotationArray[i];
        if(![annotation isCluster]){
            CLLocation * loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];

            CLLocationDistance distance = [self.screenCenter distanceFromLocation:loc];
            
            if(distance <= minDistance){
                minDistance = distance;
                toShow = annotation;
            }
        }
    }
    
    return toShow;
}

// Always show a callout when an annotation is tapped.
- (BOOL)mapView:(MKMapView *)mapView annotationCanShowCallout:(id <MKAnnotation>)annotation {
    return NO;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    view.layer.zPosition = 1;
    if([view isKindOfClass:[ShoutRMMarker class]]){
        ShoutRMMarker *marker = (ShoutRMMarker *)view;
        [marker didPressButtonWithName:@"profile"];
    }
    if([view isKindOfClass:[ShoutClusterMarker class]]){
        ShoutClusterMarker *marker = (ShoutClusterMarker *)view;
        KPAnnotation *annotation = marker.annotation;
        CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude);
        MKCoordinateRegion adjustedRegion = [mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoord, annotation.radius+100, annotation.radius+100)];
        [mapView setRegion:adjustedRegion animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    view.layer.zPosition = 0;
    if([view isKindOfClass:[ShoutRMMarker class]]){
        ShoutRMMarker *marker = (ShoutRMMarker *)view;
        [marker didPressButtonWithName:@"profile"];
    }
}

- (void)mapView:(MKMapView *)mapView
didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[KPAnnotation class]]) {
        MKAnnotationView *annotationView = nil;
        KPAnnotation *kingpinAnnotation = (KPAnnotation *)annotation;
        
        if ([kingpinAnnotation isCluster]) {
            annotationView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"cluster"];
            
            if (annotationView == nil) {
                annotationView = [[ShoutClusterMarker alloc] initWithAnnotation:kingpinAnnotation reuseIdentifier:@"cluster"];
            }
            ((ShoutClusterMarker *)annotationView).title = kingpinAnnotation.title;
            annotationView.canShowCallout = NO;
            return annotationView;
        } else {
            SOAnnotation *soannotation = [kingpinAnnotation.annotations anyObject];

            UIImage *image = soannotation.profileImage;
            ShoutRMMarker *annotationView;
            NSString *identifier = @"";
            if(soannotation.pinColor){
                identifier = @"pin";
                identifier = [identifier stringByAppendingString:soannotation.pinColor];
            }
            if(soannotation.isStatic){
                identifier = @"businessPin";
                if(soannotation.userInfo[@"pinType"]){
                    identifier = [identifier stringByAppendingString:soannotation.userInfo[@"pinType"]];
                }
            }
            
            annotationView = (ShoutRMMarker *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
            
            if (!annotationView)
            {
                annotationView = [[ShoutRMMarker alloc] initWithAnnotation:soannotation reuseIdentifier:identifier image:image];
                if(soannotation.isStatic){
                    annotationView.layer.zPosition = 1;
                }
                annotationView.shout = soannotation.subtitle;
                annotationView.canShowCallout = NO;
            }
            [annotationView scaleForZoomLevel:mapView.zoomLevel];
            annotationView.profileImage = image;
            [annotationView setOnline:soannotation.online];
            return annotationView;
        }
        
    }
    
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    // This is boilerplate code to connect tile overlay layers with suitable renderers
    //
    if ([overlay isKindOfClass:[MBXRasterTileOverlay class]])
    {
        MBXRasterTileRenderer *renderer = [[MBXRasterTileRenderer alloc] initWithTileOverlay:overlay];
        return renderer;
    }
    return nil;
}

#pragma mark -ClusterDelegate

- (void)clusteringController:(KPClusteringController *)clusteringController configureAnnotationForDisplay:(KPAnnotation *)annotation {
    annotation.title = [NSString stringWithFormat:@"%lu", (unsigned long)annotation.annotations.count];
    annotation.subtitle = [NSString stringWithFormat:@"%.0f meters", annotation.radius];
}

- (BOOL)clusteringControllerShouldClusterAnnotations:(KPClusteringController *)clusteringController {
    if(self.mapView.zoomLevel > 17){
        self.mapIsClustered = false;
    }
    else if (self.mapView.zoomLevel < 8){
        self.mapIsClustered = true;
    }
    else{
        NSSet *annotationSet = [self.mapView annotationsInMapRect:[self.mapView visibleMapRect]];
        NSArray *annotationArray = [annotationSet allObjects];
        int count = 0;
        for(int i = 0; i<[annotationArray count]; i++){
            KPAnnotation * annotation = annotationArray[i];
            if([annotation isCluster]){
                count += [[annotation annotations] count];
            }
            else{
                count++;
            }
        }
        self.mapIsClustered = count > 30;
    }
    return self.mapIsClustered;
}


@end
