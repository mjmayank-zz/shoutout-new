//
//  LocationManager.m
//  moment
//
//  Created by Mayank Jain on 9/24/13.
//  Copyright (c) 2013 Mayank Jain. All rights reserved.
//

#import "LocationManager.h"

@interface LocationManager() {
@private
    CLLocationManager *manager;
}

@end

static LocationManager *sharedLocationManager = nil;

@implementation LocationManager

+ (LocationManager *)sharedLocationManager {
    static LocationManager *sharedLocationManager;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[LocationManager alloc] init];
    });
    
    return sharedLocationManager;
}

+(id)initLocationManager {
    @synchronized(self) {
        if(sharedLocationManager == nil)
            sharedLocationManager = [[LocationManager alloc] init];
    }
    return sharedLocationManager;
}

-(id)init {
    if(self = [super init]) {
        manager = [[CLLocationManager alloc] init];
        [manager setDelegate:self];
        [manager setPausesLocationUpdatesAutomatically:YES];
        if([manager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
            [manager setAllowsBackgroundLocationUpdates:YES];
        }
        if([PFUser currentUser] && [PFUser currentUser][@"geo"]){
            PFGeoPoint *point = [PFUser currentUser][@"geo"];
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
            _lastLocation = loc;
        }
    }
    return self;
}

#pragma mark -
#pragma mark Location Methods

-(void)enterBackgroundMode{
    if([CLLocationManager locationServicesEnabled]){
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways && ![[PFUser currentUser][@"static"] boolValue] && [[PFUser currentUser][@"visible"] boolValue]){
            [manager stopUpdatingLocation];
            [manager startMonitoringVisits];
            [manager startMonitoringSignificantLocationChanges];
        }
        else{
            [self stopLocationUpdates];
        }
    }
}

-(void)enterForegroundMode{
    if(![[PFUser currentUser][@"static"] boolValue]){
        [manager startUpdatingLocation];
        manager.distanceFilter = 10.0;
        [manager startMonitoringVisits];
        [manager startMonitoringSignificantLocationChanges];
    }
}

-(void)stopLocationUpdates {
    [manager stopUpdatingLocation];
    [manager stopMonitoringVisits];
    [manager stopMonitoringSignificantLocationChanges];
}

#pragma mark -
#pragma mark Location Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if([locations count] > 0) {
        CLLocation *location = [locations lastObject];
        [self updateUserLocation:location];
    }
}

-(void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit{
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:visit.coordinate altitude:0.0 horizontalAccuracy:visit.horizontalAccuracy verticalAccuracy:0.0 timestamp:[NSDate date]];
    [self updateUserLocation:location];
}

-(void)updateUserLocation:(CLLocation *)loc{
    NSLog(@"%@", loc);
    if((loc.coordinate.latitude != 0.0 && loc.coordinate.longitude != 0.0)){
        [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
        CLLocation *oldLocation = self.lastLocation;
        _lastLocation = loc;
        
        if(oldLocation == nil || [oldLocation distanceFromLocation:loc] > 10){
            if([PFUser currentUser]){
                NSString *longitude = [NSString stringWithFormat:@"%f", loc.coordinate.longitude ];
                NSString *latitude = [NSString stringWithFormat:@"%f", loc.coordinate.latitude ];
                Firebase *shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
                [[shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
                
                [[PFUser currentUser] saveInBackground];
                NSLog(@"network request made");
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_LocationUpdate object:_lastLocation];
}

@end
