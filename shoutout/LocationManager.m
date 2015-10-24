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
        [manager pausesLocationUpdatesAutomatically];
        if([manager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
            [manager setAllowsBackgroundLocationUpdates:YES];
        }
    }
    return self;
}

#pragma mark -
#pragma mark Location Methods

-(void)startBackgroundLocationUpdates {
    [manager startMonitoringVisits];
    [manager startMonitoringSignificantLocationChanges];
}

-(void)stopBackgroundLocationUpdates {
    [manager stopMonitoringVisits];
    [manager stopMonitoringSignificantLocationChanges];
    [manager stopUpdatingLocation];
}

-(void)startLocationUpdates {
    [manager startUpdatingLocation];
    [manager startMonitoringVisits];
    [manager startMonitoringSignificantLocationChanges];
}

-(void)stopLocationUpdates {
    [manager stopUpdatingLocation];
}

#pragma mark -
#pragma mark Location Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if([locations count] > 0) {
        _lastLocation = [locations lastObject];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_LocationUpdate object:_lastLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit{
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:visit.coordinate altitude:0.0 horizontalAccuracy:visit.horizontalAccuracy verticalAccuracy:0.0 timestamp:[NSDate date]];
    _lastLocation = location;
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_LocationUpdate object:_lastLocation];
}

@end
