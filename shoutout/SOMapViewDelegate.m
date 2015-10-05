//
//  SOMapViewDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 9/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOMapViewDelegate.h"

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
    NSLog(@"Number of annotations in rect: %lu", (unsigned long)annotationSet.count);
    NSArray *annotationArray = [annotationSet allObjects];
    
    if([annotationArray count] > 0){
        CLLocationDegrees centerLatitude = mapView.centerCoordinate.latitude;
        CLLocationDegrees centerLongitude = mapView.centerCoordinate.longitude;
        
        CLLocation * screenCenter = [[CLLocation alloc] initWithLatitude:centerLatitude longitude:centerLongitude];
        
        SOAnnotation * toShow = annotationArray[0];
        
        CLLocationDistance minDistance = [screenCenter distanceFromLocation:[[CLLocation alloc] initWithLatitude:toShow.coordinate.latitude longitude:toShow.coordinate.longitude]];
        
        
        for(int i = 0; i<[annotationArray count]; i++){
            SOAnnotation * annotation = annotationArray[i];
            
            CLLocation * loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
            
            CLLocationDistance distance = [screenCenter distanceFromLocation:loc];
            
            if(distance <= minDistance){
                minDistance = distance;
                toShow = annotation;
            }
            
        }
        [mapView selectAnnotation:toShow animated:YES];
    }
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
                annotationView.centerOffset = CGPointMake(-28.0f, -67.0f);
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
            if (annotationView){
                NSLog(@"already have a pin");
            }
            if ( ! annotationView)
            {
                NSLog(@"created new pin");
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
