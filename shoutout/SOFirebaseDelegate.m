//
//  SOFirebaseDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 10/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOFirebaseDelegate.h"
#import "ViewController.h"

@implementation SOFirebaseDelegate

-(id)init{
    if(self = [super init]){
        self.shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
        self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
        self.shoutoutRootPrivacy = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/privacy"];
        self.shoutoutRootOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        
        [self registerFirebaseListeners];
    }
    return self;
}

-(void)registerFirebaseListeners{
    [self.shoutoutRoot observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self animateUser:snapshot.key toNewPosition:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserStatus:snapshot.key toNewStatus:snapshot.value];
    }];
    
    [self.shoutoutRootPrivacy observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserPrivacy:snapshot.key toNewPrivacy:snapshot.value];
    }];
    
    [self.shoutoutRootOnline observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserOnline:snapshot.key toNewOnline:snapshot.value];
    }];
}

- (void)deregisterFirebaseListeners{
    [self.shoutoutRoot removeAllObservers];
    [self.shoutoutRootStatus removeAllObservers];
    [self.shoutoutRootPrivacy removeAllObservers];
    [self.shoutoutRootOnline removeAllObservers];
}

- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([newMetadata[@"lat"] doubleValue], [newMetadata[@"long"] doubleValue] );
    SOAnnotation * annotation = ((SOAnnotation *)self.delegate.markerDictionary[userID]);
    KPAnnotation * clusterAnnotation = [self.delegate.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    if(annotation){
        [UIView animateWithDuration:0.6f
                         animations:^{
                             annotation.coordinate = coordinate;
                         }];
    }
    if(clusterAnnotation){
        if(![clusterAnnotation isCluster]){
            [UIView animateWithDuration:0.6f
                             animations:^{
                                 clusterAnnotation.coordinate = coordinate;
                             }];
        }
    }
    
    [self.delegate.mapViewDelegate.clusteringController refresh:YES];
}

- (void) changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata {
    SOAnnotation *annotation = self.delegate.markerDictionary[userID];
    KPAnnotation * clusterAnnotation = [self.delegate.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    
    if(annotation){
        annotation.subtitle = newMetadata[@"status"];
    }
    
    if(clusterAnnotation){
        if(![clusterAnnotation isCluster]){
            [self.delegate.mapView deselectAnnotation:clusterAnnotation animated:NO];
            self.delegate.mapView.selectedAnnotations = @[clusterAnnotation];
            //            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
}

- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata {
    SOAnnotation *annotation = self.delegate.markerDictionary[userID];
    KPAnnotation * clusterAnnotation = [self.delegate.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    
    if ([NSStringFromClass([clusterAnnotation class]) isEqualToString:@"KPAnnotation"]) {
        if(annotation && ![clusterAnnotation isCluster]){
            if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
                [self.delegate.mapView removeAnnotation:clusterAnnotation];
            }
        }
        else{
            
        }
    }
}

- (void) changeUserOnline:(NSString *)userID toNewOnline:(NSString *)newMetadata {
    SOAnnotation *annotation = self.delegate.markerDictionary[userID];
    
    if(annotation){
        if([newMetadata isEqualToString:@"YES"]){
            annotation.online = YES;
        }
        else{
            annotation.online = NO;
        }
    }
}

@end
