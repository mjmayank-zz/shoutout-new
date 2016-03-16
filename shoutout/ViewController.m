//
//  ViewController.m
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#define kParseObjectClassKey    "StatusObject"
#define kParseObjectGeoKey      "geo"
#define kParseObjectImageKey    "imageFile"
#define kParseObjectUserKey     "user"
#define kParseObjectCaption     "caption"
#define kParseObjectVisibleKey  "visible"
#define Notification_LocationUpdate @"LocationUpdate"

#define SO_POPOVER_VERTICAL_SHIFT 80
#define SO_POPOVER_HORIZ_PADDING 20

#import "ViewController.h"
#import "LocationManager.h"
#import <AudioToolbox/AudioServices.h>
#import "Shoutout-Swift.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
// List
@property (strong, nonatomic) SOListViewController *listViewVC;
@property (strong, nonatomic) NSLayoutConstraint* listViewBottomConstraint;

// Inbox
@property (strong, nonatomic) SOInboxViewController *inboxVC;
@property (strong, nonatomic) NSLayoutConstraint* inboxBottomConstraint;

@property (strong, nonatomic) SOComposeStatusViewController *composeStatusVC;
@property (strong, nonatomic) NSCache *profileImageCache;
@property (strong, nonatomic) IBOutlet UIButton *loadButton;

// NUX
@property (strong, nonatomic) SOPopoverViewController* nuxPopover;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPermissions"];
    
    self.markerDictionary = [[NSMutableDictionary alloc] init];
    self.profileImageCache = [[NSCache alloc] init];
    
    [[PFUser currentUser] fetchInBackground];

    // Create the list view
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.listViewVC = [storyboard instantiateViewControllerWithIdentifier:@"soListView"];
    // Create the inbox view
    self.inboxVC = [storyboard instantiateViewControllerWithIdentifier:@"soInboxView"];
    self.inboxVC.profileImageCache = self.profileImageCache;
    self.inboxVC.delegate = self;
    
    // initialize the map view
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (CLLocationCoordinate2DMake(40.1105, -88.2284), 500, 500);
    [self.mapView setRegion:region animated:NO];
    // set the map's center coordinate
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(40.1105, -88.2284)
                             animated:NO];
    [self.view insertSubview:self.mapView aboveSubview:self.map];
    self.mapViewDelegate = [[SOMapViewDelegate alloc] initWithMapView:self.mapView];
    self.mapViewDelegate.listViewVC = self.listViewVC;
    self.mapViewDelegate.delegate = self;
    
    self.mapView.delegate = self.mapViewDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];

    //gesture recognizers so that delegate events fire as we pan/pinch instead of after it finishes
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    pinchGesture.delegate = self;
    [self.mapView addGestureRecognizer:pinchGesture];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    panGesture.delegate = self;
    [self.mapView addGestureRecognizer:panGesture];
    
    //Create popovers for inbox and list
    [self setupPopovers];
    
    [self registerNotifications];
    
    [self registerFirebaseListeners];
    
    self.scoreLabel.layer.cornerRadius = 5.0;
    self.scoreLabel.clipsToBounds = YES;
    [self updateScoreLabel];
    
    //set up mailbox
    [self.unreadIndicator.layer setCornerRadius:self.unreadIndicator.frame.size.height/2];
    self.unreadIndicator.layer.masksToBounds = YES;
    
    CLLocationCoordinate2D userLocation = CLLocationCoordinate2DMake(40.1105, -88.2284);
    self.previousLocation = [LocationManager sharedLocationManager].lastLocation;
    if (self.previousLocation) {
        userLocation = self.previousLocation.coordinate;
    }
    [self centerMapToUserLocation];
    [self updateMapWithLocation:userLocation];
    // set the map's center coordinate
    
    // Associate the device with a user
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = [PFUser currentUser];
    [installation saveInBackground];
    
    // Check if the NUX has been shown yet
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    BOOL shownNUX = [defaults boolForKey:kUserDefaultShownNUXKey];
//    BOOL shownNUX = false;
    if (!shownNUX) {
        [self showNUX];
    } else {
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            CLLocationManager* locationManager = [ViewController sharedLocationManager];
            [locationManager requestAlwaysAuthorization];
        }
        [self checkLocationPermission];
//        [self promptForCheckinPermission];
    }
}

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *sharedLocationManager;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[CLLocationManager alloc] init];
    });
    
    return sharedLocationManager;
}

- (void)completeNUX {
    // First, remove the popover
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kUserDefaultShownNUXKey];
    [defaults synchronize];
    [self.nuxPopover removeFromParentViewController];
    [self.nuxPopover.view removeFromSuperview];
    self.nuxPopover = nil;
    
    CLLocationManager* locationManager = [ViewController sharedLocationManager];
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [locationManager requestAlwaysAuthorization];
    } else{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Your location is required for Shoutout to work" message:@"You can disable this from the settings menu" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    // Re-enable buttons after they complete NUX
    self.inboxButton.enabled = YES;
    self.listButton.enabled = YES;
    self.composeButton.enabled = YES;
    self.settingsButton.enabled = YES;
    self.locateButton.enabled = YES;
}

- (void)setupPopovers {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    // Create the popovers
    SOPopoverViewController* listPopover = [storyboard instantiateViewControllerWithIdentifier:@"soPopover"];
    [self addChildViewController:listPopover];
    [listPopover didMoveToParentViewController:self];
    self.listViewContainer = listPopover.view;
    [listPopover updateChildController:self.listViewVC];
    [self.view insertSubview:self.listViewContainer belowSubview:self.slidingView];
    self.listViewVC.countLabel = listPopover.popoverTitle;
    
    SOPopoverViewController* inboxPopover = [storyboard instantiateViewControllerWithIdentifier:@"soPopover"];
    [self addChildViewController:inboxPopover];
    [inboxPopover didMoveToParentViewController:self];
    self.inboxContainer = inboxPopover.view;
    [inboxPopover updateChildController:self.inboxVC];
    [self.view insertSubview:self.inboxContainer belowSubview:self.slidingView];
    inboxPopover.popoverTitle.text = @"Inbox";
    
    // TODO: better handling of the pip location
    [listPopover updatePipLocation:self.listButton.frame.origin.x];
    NSLog(@"%f", self.listButton.frame.origin.x);
    [inboxPopover updatePipConstraint:self.inboxButton];
//    [inboxPopover updatePipLocation:self.inboxButton.frame.origin.x];
    NSLog(@"%f", self.inboxButton.frame.origin.x);
    
    // Add constraints to the popovers. Resizes them to have margins
    NSMutableArray* constraints = [NSMutableArray array];
    NSDictionary* views = @{
                            @"listPopover": self.listViewContainer,
                            @"inboxPopover": self.inboxContainer,
                            };
    NSDictionary* metrics = @{
                              @"padding": @SO_POPOVER_HORIZ_PADDING
                              };
    
    [self.listViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.inboxContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Horizontal padding
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[listPopover]-padding-|" options:0 metrics:metrics views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[inboxPopover]-padding-|" options:0 metrics:metrics views:views]];
    
    // Height
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.listViewContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.8 constant:0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.inboxContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.8 constant:0]];
    
    // Bottom margin
    self.listViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.listViewContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.listButton attribute:NSLayoutAttributeTop multiplier:1 constant:SO_POPOVER_VERTICAL_SHIFT];
    self.inboxBottomConstraint = [NSLayoutConstraint constraintWithItem:self.inboxContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.inboxButton attribute:NSLayoutAttributeTop multiplier:1 constant:SO_POPOVER_VERTICAL_SHIFT];
    [constraints addObject:self.listViewBottomConstraint];
    [constraints addObject:self.inboxBottomConstraint];
    
    [NSLayoutConstraint activateConstraints:constraints];
    
    
    // Hide the views initially
    self.listViewContainer.layer.opacity = 0;
    self.inboxContainer.layer.opacity = 0;
}

- (void)showNUX {
    // Disable buttons until they complete NUX
    self.inboxButton.enabled = NO;
    self.listButton.enabled = NO;
    self.composeButton.enabled = NO;
    self.settingsButton.enabled = NO;
    self.locateButton.enabled = NO;
    
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    SOPopoverViewController* tutPopover = [storyboard instantiateViewControllerWithIdentifier:@"soPopover"];
    self.nuxPopover = tutPopover;
    [self addChildViewController:tutPopover];
    [tutPopover didMoveToParentViewController:self];
    [self.view addSubview:tutPopover.view];
    
    SONUXTutorialCardViewController* tutController = [storyboard instantiateViewControllerWithIdentifier:@"soTutorialCard"];
    [tutPopover updateChildController:tutController];
    [tutPopover setShowsTitle:NO];
    tutController.popover = tutPopover;
    tutController.delegate = self;
    
    // Auto Layout for NUX popover
    NSMutableArray* constraints = [NSMutableArray array];
    NSDictionary* views = @{
                            @"popover": tutPopover.view
                            };
    NSDictionary* metrics = @{
                              @"padding": @SO_POPOVER_HORIZ_PADDING
                              };
    
    [tutPopover.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // Horizontal padding
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[popover]-padding-|"
                                                                             options:0
                                                                             metrics:metrics
                                                                               views:views]];
    // Top margin
    [constraints addObject:[NSLayoutConstraint constraintWithItem:tutPopover.view
                                                        attribute:NSLayoutAttributeTopMargin
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1
                                                         constant:50.0f]];
    // Bottom margin
    [constraints addObject:[NSLayoutConstraint constraintWithItem:tutPopover.view
                                                        attribute:NSLayoutAttributeBottom
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.inboxButton
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1
                                                         constant:0]];
    [NSLayoutConstraint activateConstraints:constraints];
    
    // Show the initial tutorial
    [tutController showInitialController];
}


- (void)updateScore:(NSNotification *)notification{
    [self updateScoreLabel];
}

- (void)updateScoreLabel{
    if([[PFUser currentUser] objectForKey:@"score"] != NULL){
        self.scoreLabel.text = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectForKey:@"score"]];
    }
}

- (void)centerMapOnUser:(NSNotification *)notification{
    SOAnnotation *annotation = self.markerDictionary[notification.userInfo[@"objectId"]];
    if(annotation){
        [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
        [self.mapView selectAnnotation:annotation animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self checkNumberOfNewMessages];
    [self checkToBlockMap];
}

- (void)dealloc {
    [self unregisterNotifications];
    self.mapView.delegate = nil;
    [self.mapView removeFromSuperview];
    [self deregisterFirebaseListeners];
}

- (void)applicationWillEnterBackground:(NSNotification*)notification{
    [self deregisterFirebaseListeners];
}

- (void)applicationWillEnterForeground:(NSNotification*)notification{
    if([PFUser currentUser]){ //THIS IS A HACK. MAKE SURE VC IS DEALLOCATING PROPERLY
        [self registerFirebaseListeners];
        [self updateMapWithLocation:self.previousLocation.coordinate];
        [self checkNumberOfNewMessages];
        [self checkLocationPermission];
//        [self promptForCheckinPermission];
        [self checkToBlockMap];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:
     Notification_LocationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterBackground:) name:
     UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:
     UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replyNotificationReceived:) name:
     @"replyToShout" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScore:) name:
     @"scoreUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(centerMapOnUser:) name:
     @"centerMapOnUser" object:nil];
}

- (void)unregisterNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_LocationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"replyToShout" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scoreUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"centerMapOnUser" object:nil];
}

- (void)checkNumberOfNewMessages{
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    [query whereKey:@"toArray" equalTo:[PFUser currentUser]];
    [query whereKey:@"read" notEqualTo:[NSNumber numberWithBool:YES]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if(number != 0){
            self.unreadIndicator.hidden = NO;
            self.unreadIndicator.text = [NSString stringWithFormat:@"%d", number];
        }
        else{
            self.unreadIndicator.hidden = YES;
        }
    }];
}

- (void)checkToBlockMap{
    if(![[PFUser currentUser][@"visible"] boolValue]){
        [self performSegueWithIdentifier:@"blockMapSegue" sender:self];
    }
}

- (void)sendPush{ //DANGEROUS METHOD. SENDS A PUSH MEHTOD TO EVERYONE.
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Send push?" message:@"This will send a push to everyone" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //    PFGeoPoint * geoLoc = [PFGeoPoint geoPointWithLatitude:40.11284489654015
        //                                                 longitude:-88.23131809950641];
        PFQuery *query = [PFUser query];
        [query whereKey:@"attendedJoes" equalTo:[NSNumber numberWithBool:YES]];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                
                for (PFObject *obj in objects ) {
                    
                    // Create our Installation query
                    PFQuery *pushQuery = [PFInstallation query];
                    [pushQuery whereKey:@"user" equalTo:obj];
                    
                    NSString * fullMessage = [NSString stringWithFormat:@"%@: %@", [PFUser currentUser][@"username"], @"Thanks for coming to Joe's last night! We'll be doing more events with free cover at other bars as well, so stay tuned! Tell your friends to download Shoutout!"];
                    
                    // Send push notification to query
                    NSDictionary *data = @{
                                           @"alert":fullMessage,
                                           };
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery]; // Set our Installation query
                    [push setData:data];
                    [push sendPushInBackground];
                }
            }
        }];
    }];
    [alertController addAction:yesAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];

}

- (void)promptForCheckinPermission{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways && ![[NSUserDefaults standardUserDefaults] boolForKey:@"hasCheckinPermissions"] && [PFUser currentUser][@"visible"]){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString( @"Do you want to continue to leave this service enabled until the next time you open the app?", @"" ) message:NSLocalizedString(@"Shoutout is taking your location and sharing it on the map for other users to see." , @"" ) preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yes", @"" ) style:UIAlertActionStyleDefault handler:nil];
        
        UIAlertAction *yesAlwaysAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Yup, don't ask me again", @"" ) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasCheckinPermissions"];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"No, take me to settings", @"" ) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"openSettingsSegue" sender:self];
        }];
        
        [alertController addAction:yesAction];
        [alertController addAction:yesAlwaysAction];
        [alertController addAction:noAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)checkLocationPermission{
    if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString( @"Shoutout needs your location!", @"" ) message:NSLocalizedString( @"Please change your location permission to Always", @"" ) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Cancel", @"" ) style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"" ) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:
                                                        UIApplicationOpenSettingsURLString]];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:settingsAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)allowMapLoad{
    [self.loadButton setHidden:NO];
}

- (void)disallowMapLoad{
    [self.loadButton setHidden:YES];
}

- (void)updateMapWithLocation:(CLLocationCoordinate2D)location{
    // Construct quer
    [PFCloud callFunctionInBackground:@"queryUsers"
                       withParameters:@{@"lat": [NSNumber numberWithDouble:location.latitude],
                                        @"long": [NSNumber numberWithDouble:location.longitude],
                                        @"user": [PFUser currentUser].objectId,
                                        @"debug": @NO}
                                block:^(NSArray *objects, NSError *error) {
                                    if (!error) {
                                        // The find succeeded.
                                        
                                        NSLog(@"Successfully retrieved %lu statuses.", (unsigned long)objects.count);
                                        
                                        for (PFObject * obj in objects){
                                            if([self.markerDictionary objectForKey:[obj objectId]]){
                                                [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                                            }
                                            if (obj[@"statusObj"]) {
                                                [obj[@"statusObj"] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                                                    [self addUserToAnnotationDictionary:obj];
                                                }];
                                            }
                                            else{
                                                [self addUserToAnnotationDictionary:obj];
                                            }
                                        }
                                        [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
                                        
                                    } else {
                                        // Log details of the failure
                                        NSLog(@"Parse error: %@ %@", error, [error userInfo]);
                                    }
                                }];
}

- (void) addUserToAnnotationDictionary:(PFObject *)obj{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(((PFGeoPoint *)obj[@"geo"]).latitude, ((PFGeoPoint *)obj[@"geo"]).longitude);
    NSString *title = @"";
    if(obj[@"username"]){
        title = obj[@"username"];
    }
    if(obj[@"displayName"]){
        title = obj[@"displayName"];
    }
    if([obj[@"anonymous"] boolValue]){
        title = @"";
    }
    NSString *subtitle = obj[@"status"];
    if (obj[@"statusObj"]){
        subtitle = obj[@"statusObj"][@"status"];
    }
    SOAnnotation *annotation = [[SOAnnotation alloc] initWithTitle:title Subtitle:subtitle Location:coordinate];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    if(obj.updatedAt) //used for date on bubble
        dict[@"updatedAt"] = obj.updatedAt;
    if(obj[@"pinType"]){
        dict[@"pinType"] = obj[@"pinType"];
    }
    if(obj[@"pinColor"]){
        annotation.pinColor = obj[@"pinColor"];
    }
    annotation.objectId = obj.objectId;
    annotation.userInfo = dict;
    annotation.online = [obj[@"online"] boolValue];
    annotation.isStatic = [obj[@"static"] boolValue];
    
    [self.mapViewDelegate.tree insertObject:annotation];
    
    if(obj[@"visible"]){
        if ([self.profileImageCache objectForKey:[obj objectId]]) {
            UIImage *image = [self.profileImageCache objectForKey:[obj objectId]];
            annotation.profileImage = image;
            if([self.markerDictionary objectForKey:[obj objectId]]){
                [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
            }
            [self.markerDictionary setObject:annotation forKey:[obj objectId]];
            [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
        }
        else if([self.markerDictionary objectForKey:[obj objectId]]){
            annotation.profileImage = ((SOAnnotation *)[self.markerDictionary objectForKey:[obj objectId]]).profileImage;
            if(annotation.profileImage){
                [self.profileImageCache setObject:annotation.profileImage forKey:obj.objectId];
            }
            [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
            [self.markerDictionary setObject:annotation forKey:[obj objectId]];
            [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
        }
        else{
            [self loadImageForObject:obj andAnnotation:annotation];
        }
        
    }
}

-(void)loadImageForObject:(PFObject *)obj andAnnotation:(SOAnnotation *)annotation{
    if(obj[@"profileImage"]){
        [obj[@"profileImage"] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            PFFile *file = object[@"image"];
            [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                annotation.profileImage = [UIImage imageWithData:data];
                [self.profileImageCache setObject:annotation.profileImage forKey:obj.objectId];
            }];
            
            if([self.markerDictionary objectForKey:[obj objectId]]){
                [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
            }
            [self.markerDictionary setObject:annotation forKey:[obj objectId]];
            [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
        }];
    }
}

#pragma mark -FirebaseEvents

- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([newMetadata[@"lat"] doubleValue], [newMetadata[@"long"] doubleValue] );
    SOAnnotation * annotation = ((SOAnnotation *)self.markerDictionary[userID]);
    KPAnnotation * clusterAnnotation = [self.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
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
    
    [self.mapViewDelegate.clusteringController refresh:YES];
}

- (void) changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata {
    SOAnnotation *annotation = self.markerDictionary[userID];
    KPAnnotation * clusterAnnotation = [self.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    
    if(annotation){
        annotation.subtitle = newMetadata[@"status"];
    }
    
    if(clusterAnnotation){
        if(![clusterAnnotation isCluster]){
            [self.mapView deselectAnnotation:clusterAnnotation animated:NO];
            self.mapView.selectedAnnotations = @[clusterAnnotation];
//            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
}

- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata {
    SOAnnotation *annotation = self.markerDictionary[userID];
    KPAnnotation * clusterAnnotation = [self.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];

    if ([NSStringFromClass([clusterAnnotation class]) isEqualToString:@"KPAnnotation"]) {
        if(annotation && ![clusterAnnotation isCluster]){
            if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
                [self.mapView removeAnnotation:clusterAnnotation];
            }
        }
        else{
            
        }
    }
}

- (void) changeUserOnline:(NSString *)userID toNewOnline:(NSString *)newMetadata {
    SOAnnotation *annotation = self.markerDictionary[userID];
//    KPAnnotation * clusterAnnotation = [self.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    
    if(annotation){
        if([newMetadata isEqualToString:@"YES"]){
            annotation.online = YES;
        }
        else{
            annotation.online = NO;
        }
    }
}

-(void)registerFirebaseListeners{
    self.shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
    self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
    self.shoutoutRootPrivacy = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/privacy"];
    self.shoutoutRootOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
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

#pragma mark -Button Presses

- (IBAction)shoutOutButtonPressed:(id)sender {
    [self animateSlidingView];
}

- (void)centerMapToUserLocation{
    if(self.previousLocation){
        [self.mapView setCenterCoordinate:self.previousLocation.coordinate animated:YES];
    }
}

- (IBAction)inboxButtonPressed:(id)sender {
    [self checkNumberOfNewMessages];
    [self closeListView];
    if(self.inboxBottomConstraint.constant == SO_POPOVER_VERTICAL_SHIFT){
        [self openInboxView];
    }
    else{
        [self closeInboxView];
    }
}

- (void)openInboxView{
    [self.view layoutIfNeeded];
    [self.inboxVC getMessages];
    self.inboxBottomConstraint.constant = 0;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.inboxContainer.layer.opacity = 1;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)closeInboxView{
    [self.view layoutIfNeeded];
    self.inboxBottomConstraint.constant = SO_POPOVER_VERTICAL_SHIFT;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.inboxContainer.layer.opacity = 0;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (IBAction)listViewButtonPressed:(id)sender {
    [self closeInboxView];
    NSSet *annotationSet = [self.mapView annotationsInMapRect:[self.mapView visibleMapRect]];
    NSArray *annotationArray = [annotationSet allObjects];
    
    [self.listViewVC updateAnnotationArray:annotationArray];
    
    if(!self.listViewVC.open){
        [self openListView];
    }
    else{
        [self closeListView];
    }
}

- (void)closeListView{
    [self.view layoutIfNeeded];
    self.listViewVC.open = NO;
    self.listViewBottomConstraint.constant = SO_POPOVER_VERTICAL_SHIFT;
    self.centerMarkYConstraint.constant = 0;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         CGRect rect = CGRectMake(0, 0,  self.view.bounds.size.width, self.view.bounds.size.height);
                         self.mapView.frame = rect;
                         self.listViewContainer.layer.opacity = 0;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)openListView{
    [self.view layoutIfNeeded];
    self.listViewVC.open = YES;
    self.listViewBottomConstraint.constant = 0;
    self.centerMarkYConstraint.constant = self.view.bounds.size.height / 4.0;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         self.listViewContainer.layer.opacity = 1;
                         CGRect rect = CGRectMake(0, -1 * self.mapView.frame.size.height/2.0,  self.view.bounds.size.width, self.mapView.frame.size.height * 1.5);
                         self.mapView.frame = rect;
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (IBAction)centerButtonPressed:(id)sender {
    [self centerMapToUserLocation];
}

- (IBAction)loadMapPressed:(id)sender {
    [self updateMapWithLocation:self.mapView.centerCoordinate];
    [self.loadButton setHidden:YES];
}

#pragma -mark Update Status View

- (void)closeUpdateStatusView{
    [self.view layoutIfNeeded];
    self.slidingViewConstraint.constant = -500;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)openUpdateStatusView{
    [self.view layoutIfNeeded];
    self.slidingViewConstraint.constant = -20;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self.composeStatusVC openUpdateStatusView];
                     }];
    [PFAnalytics trackEvent:@"openedComposeView" dimensions:nil];
}

- (void)openUpdateStatusViewWithStatus:(NSString *)status{
    [self.composeStatusVC setStatusText:status];
    [self openUpdateStatusView];
    [PFAnalytics trackEvent:@"openedComposeView" dimensions:@{@"status":status}];
}

- (void)animateSlidingView{
    if(self.slidingViewConstraint.constant != -20){
        [self openUpdateStatusView];
    }
    else{
        [self closeUpdateStatusView];
    }
}

#pragma -mark Notification Events
- (void)replyNotificationReceived:(NSNotification *)notification{
    NSDictionary * userInfo = notification.userInfo;
    NSString * username = userInfo[@"username"];
    [self openUpdateStatusViewWithStatus:[NSString stringWithFormat:@"@%@ ", username]];
}

-(void)mapPanned{
    [self.mapViewDelegate mapView:self.mapView regionIsChanging:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if([gestureRecognizer class] == [otherGestureRecognizer class]){
        return YES;
    }
    else{
        return NO;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"openSettingsSegue"]) {
        ((SOSettingsViewController*)segue.destinationViewController).oldVC = self;
    }
    else if([segue.identifier isEqualToString:@"composeStatusView"]){
        self.composeStatusVC = segue.destinationViewController;
        self.composeStatusVC.delegate = self;
    }
}

#pragma mark -LocationManager Notifications
-(void)locationUpdated:(NSNotification *)notification{
    CLLocation * loc = notification.object;
    [self updateUserLocation:loc];
}

- (void)updateUserLocation:(CLLocation *)loc{
    NSLog(@"%@", loc);
    if((loc.coordinate.latitude != 0.0 && loc.coordinate.longitude != 0.0)){
        CLLocation *oldLocation = self.previousLocation;
        self.previousLocation = loc;
        
        if(oldLocation == nil){
            [self centerMapToUserLocation];
            [self updateMapWithLocation:loc.coordinate];
        }
        else if([oldLocation distanceFromLocation:loc] > 5000){
            [self centerMapToUserLocation];
            [self updateMapWithLocation:loc.coordinate];
        }
        if(oldLocation == nil || [oldLocation distanceFromLocation:loc] > 10){
            if([PFUser currentUser]){
                if(![PFUser currentUser][@"static"]){
                    if(![self.markerDictionary objectForKey:[[PFUser currentUser] objectId]]){
                        [[PFUser currentUser][@"statusObj"] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                            [self addUserToAnnotationDictionary:object];
                        }];
                    }
                    else{
                        SOAnnotation *annotation = [self.markerDictionary objectForKey:[[PFUser currentUser] objectId]];
                        annotation.coordinate = loc.coordinate;
                    }
                }
            }
        }
    }
}

@end
