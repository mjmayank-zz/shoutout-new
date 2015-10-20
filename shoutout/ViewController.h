//
//  ViewController.h
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Firebase/Firebase.h>
#import "SOAnnotation.h"
#import "ShoutRMMarker.h"
#import "ShoutClusterMarker.h"
#import "kingpin.h"
#import "MKMapView+ZoomLevel.h"
#import <LocationKit/LocationKit.h>
#import "SOMapViewDelegate.h"
#import "SOComposeStatusView.h"
@import MapKit;

@interface ViewController : UIViewController<PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UITextViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, KPClusteringControllerDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView * map;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *slidingView;
@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UITextView *statusTextView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UILabel *statusCharacterCount;

@property (strong, nonatomic) IBOutlet UILabel *unreadIndicator;

@property (strong, nonatomic) NSMutableDictionary * markerDictionary;

@property (assign, nonatomic) BOOL shelf;

@property (strong, nonatomic) CLLocation * previousLocation;

@property (strong, nonatomic) Firebase* shoutoutRoot;
@property (strong, nonatomic) Firebase* shoutoutRootStatus;
@property (strong, nonatomic) Firebase* shoutoutRootPrivacy;
@property (strong, nonatomic) Firebase* shoutoutRootOnline;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *slidingViewConstraint;

@property (strong, nonatomic) SOMapViewDelegate* mapViewDelegate;

- (void)openUpdateStatusViewWithStatus:(NSString *)status;
- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata;
- (void) changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata;
- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata;
- (void) changeUserOnline:(NSString *)userID toNewOnline:(NSString *)newMetadata;
- (void)closeUpdateStatusView;
- (void)openUpdateStatusView;

@end

