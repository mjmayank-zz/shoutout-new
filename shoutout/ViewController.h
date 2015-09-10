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
#import "Mapbox.h"
#import <Firebase/Firebase.h>
#import "SOAnnotation.h"
#import "ShoutRMMarker.h"
@import MapKit;

@interface ViewController : UIViewController<PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UITextViewDelegate, MGLMapViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet UIView * map;
@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UITextField *searchTextField;
@property (strong, nonatomic) IBOutlet UIView *slidingView;
@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UITextView *statusTextView;
@property (strong, nonatomic) IBOutlet UISwitch *privacyToggle;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@property (strong, nonatomic) NSMutableDictionary * markerDictionary;

@property (assign, nonatomic) BOOL shelf;

@property (strong, nonatomic) Firebase* shoutoutRoot;
@property (strong, nonatomic) Firebase* shoutoutRootStatus;
@property (strong, nonatomic) Firebase* shoutoutRootPrivacy;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *slidingViewConstraint;

@end

