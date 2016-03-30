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
#import "SOFirebaseDelegate.h"
@import MapKit;
@class SOMapFilter;
@class SOFilterIndicatorView;

@interface ViewController : UIViewController<UITextViewDelegate, MKMapViewDelegate, KPClusteringControllerDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView * map;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) UIView *listViewContainer;
@property (strong, nonatomic) UIView *inboxContainer;

@property (strong, nonatomic) SOMapFilter *filter;
@property (strong, nonatomic) IBOutlet UIView *filterIndicatorView;
@property (strong, nonatomic) IBOutlet UILabel *filterTitle;

@property (strong, nonatomic) IBOutlet UIButton *inboxButton;
@property (strong, nonatomic) IBOutlet UIButton *listButton;
@property (strong, nonatomic) IBOutlet UIButton *composeButton;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (strong, nonatomic) IBOutlet UIButton *locateButton;

@property (strong, nonatomic) IBOutlet UILabel *unreadIndicator;

@property (strong, nonatomic) NSMutableDictionary * markerDictionary;

@property (strong, nonatomic) CLLocation * previousLocation;

@property (strong, nonatomic) SOFirebaseDelegate* firebaseDelegate;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *centerMarkYConstraint;

@property (strong, nonatomic) SOMapViewDelegate* mapViewDelegate;

- (void)openUpdateStatusViewWithStatus:(NSString *)status;
- (void)closeInboxView;
- (void)allowMapLoad;
- (void)filterAnnotations;

- (void)completeNUX;

@end

