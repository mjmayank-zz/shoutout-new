//
//  ViewController.h
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <Firebase/Firebase.h>
#import "SOAnnotation.h"
#import "ShoutRMMarker.h"
#import "ShoutClusterMarker.h"
#import "kingpin.h"
#import "MKMapView+ZoomLevel.h"
#import "SOMapViewDelegate.h"
#import "SOComposeStatusViewController.h"
#import "LocationManager.h"
@import MapKit;

@interface ViewController : UIViewController<UITextViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, KPClusteringControllerDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView * map;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *slidingView;
@property (strong, nonatomic) UIView *listViewContainer;
@property (strong, nonatomic) UIView *inboxContainer;

@property (strong, nonatomic) IBOutlet UILabel *unreadIndicator;

@property (strong, nonatomic) NSMutableDictionary * markerDictionary;

@property (strong, nonatomic) CLLocation * previousLocation;

@property (strong, nonatomic) Firebase* shoutoutRoot;
@property (strong, nonatomic) Firebase* shoutoutRootStatus;
@property (strong, nonatomic) Firebase* shoutoutRootPrivacy;
@property (strong, nonatomic) Firebase* shoutoutRootOnline;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *slidingViewConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *centerMarkYConstraint;

@property (strong, nonatomic) SOMapViewDelegate* mapViewDelegate;

- (void)openUpdateStatusViewWithStatus:(NSString *)status;
- (void)animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata;
- (void)changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata;
- (void)changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata;
- (void)changeUserOnline:(NSString *)userID toNewOnline:(NSString *)newMetadata;
- (void)closeUpdateStatusView;
- (void)openUpdateStatusView;
- (void)closeInboxView;
- (void)allowMapLoad;

@end

