//
//  SOMapViewDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 9/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOMapViewDelegate.h"
#import "Shoutout-Swift.h"

@implementation SOMapViewDelegate

-(instancetype)initWithMapView:(MKMapView *)mapView{
    if (self = [super init])
    {
        self.mapView = mapView;
        
        self.latitudeDelta = mapView.region.span.latitudeDelta;
        self.clusteringController = [[KPClusteringController alloc] initWithMapView:mapView];
        self.clusteringController.delegate = self;
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    //    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    [self.clusteringController refresh:YES];
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
    
    if([annotationArray count] > 0){
        CLLocationCoordinate2D coordinate = mapView.centerCoordinate;
        
        if(self.listViewVC.open){
            CGPoint point = CGPointMake(self.mapView.bounds.size.width/2.0, self.mapView.bounds.size.height/2.0);
            coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        }
        
        CLLocation * screenCenter = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        
        KPAnnotation *toShow = [self findClosestAnnotationToPoint:screenCenter inArray:annotationArray];
        
        if (toShow) {
            [mapView selectAnnotation:toShow animated:YES];
        }
    }
}

- (KPAnnotation *)findClosestAnnotationToPoint:(CLLocation *)screenCenter inArray:(NSArray *)annotationArray{
    KPAnnotation * toShow;
    
    CLLocationDistance minDistance = DBL_MAX;
    
    for(int i = 0; i<[annotationArray count]; i++){
        KPAnnotation * annotation = annotationArray[i];
        if(![annotation isCluster]){
            CLLocation * loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
            
            CLLocationDistance distance = [screenCenter distanceFromLocation:loc];
            
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
    if([view isKindOfClass:[ShoutRMMarker class]]){
        ShoutRMMarker *marker = (ShoutRMMarker *)view;
        [marker didPressButtonWithName:@"profile"];
    }
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
            //            annotationView.pinColor = MKPinAnnotationColorPurple;
            annotationView.canShowCallout = NO;
            return annotationView;
        } else {
            SOAnnotation *shoutoutAnnotation = [kingpinAnnotation.annotations anyObject];
            //            SOAnnotation *shoutoutAnnotation = (SOAnnotation *)annotation;
            UIImage *image = shoutoutAnnotation.profileImage;
            ShoutRMMarker *annotationView = (ShoutRMMarker *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
            if ( ! annotationView)
            {
                annotationView = [[ShoutRMMarker alloc] initWithAnnotation:shoutoutAnnotation reuseIdentifier:@"pin" image:image];
                annotationView.shout = shoutoutAnnotation.subtitle;
                annotationView.canShowCallout = NO;
            }
            [annotationView scaleForZoomLevel:mapView.zoomLevel];
            annotationView.profileImage = image;
            [annotationView setOnline:shoutoutAnnotation.online];
            return annotationView;
        }
        
    }
    
    return nil;
}

#pragma mark -ClusterDelegate

- (void)clusteringController:(KPClusteringController *)clusteringController configureAnnotationForDisplay:(KPAnnotation *)annotation {
    annotation.title = [NSString stringWithFormat:@"%lu", (unsigned long)annotation.annotations.count];
    annotation.subtitle = [NSString stringWithFormat:@"%.0f meters", annotation.radius];
}

- (BOOL)clusteringControllerShouldClusterAnnotations:(KPClusteringController *)clusteringController {
    return self.mapView.zoomLevel < 14; // Find zoom level that suits your dataset
}


@end
