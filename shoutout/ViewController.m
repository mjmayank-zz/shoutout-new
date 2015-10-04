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

#import "ViewController.h"
#import "LocationManager.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <AudioToolbox/AudioServices.h>
#import "Shoutout-Swift.h"

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation * previousLocation;
@property (assign, nonatomic) int *count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getFacebookInfo];
    
    self.count = 0;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPermissions"];
    
    self.markerDictionary = [[NSMutableDictionary alloc] init];
    
    // initialize the map view
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (CLLocationCoordinate2DMake(40.1105, -88.2284), 500, 500);
    [self.mapView setRegion:region animated:NO];
    // set the map's center coordinate
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(40.1105, -88.2284)
                             animated:NO];
    [self.view insertSubview:self.mapView belowSubview:self.slidingView];
    self.mapViewDelegate = [[SOMapViewDelegate alloc] initWithMapView:self.mapView];
    
    self.mapView.delegate = self.mapViewDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];

    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    pinchGesture.delegate = self;
    [self.mapView addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    panGesture.delegate = self;
    [self.mapView addGestureRecognizer:panGesture];
//    self.mapView.showsPointsOfInterest = false;
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
//    self.locationManager.distanceFilter = 10.0;
//    [self.locationManager startUpdatingLocation];
    
    CLLocation * locationInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:
     Notification_LocationUpdate object:locationInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterBackground:) name:
     UIApplicationWillResignActiveNotification object:locationInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:
     UIApplicationWillEnterForegroundNotification object:locationInfo];
    
    self.shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
    self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
    self.shoutoutRootPrivacy = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/privacy"];
    
    [self.shoutoutRoot observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self animateUser:snapshot.key toNewPosition:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserStatus:snapshot.key toNewStatus:snapshot.value];
    }];
     
    [self.shoutoutRootPrivacy observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserPrivacy:snapshot.key toNewPrivacy:snapshot.value];
    }];
    
    UIImage * image = [UIImage imageWithData:
             [NSData dataWithContentsOfURL:
              [NSURL URLWithString: [PFUser currentUser][@"picURL"]]]];
    self.profilePic.image = image;
    self.profilePic.layer.cornerRadius = 35.0;
    self.profilePic.layer.masksToBounds = YES;
    
    self.statusTextView.text = [PFUser currentUser][@"status"];
    
    [self.saveButton.layer setCornerRadius:4.0f];
    [self.unreadIndicator.layer setCornerRadius:self.unreadIndicator.frame.size.height/2];
    self.unreadIndicator.layer.masksToBounds = YES;
    
    CLLocationCoordinate2D userLocation = CLLocationCoordinate2DMake(40.1105, -88.2284);
    [self updateMapWithLocation:userLocation];
    // set the map's center coordinate
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self promptLogin];
    [self checkForNewMessages];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_LocationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    self.mapView.delegate = nil;
    [self.mapView removeFromSuperview];
    [self.shoutoutRoot removeAllObservers];
    [self.shoutoutRootStatus removeAllObservers];
    [self.shoutoutRootPrivacy removeAllObservers];
}

- (void)applicationWillEnterBackground:(NSNotification*)notification{
    [self.shoutoutRoot removeAllObservers];
    [self.shoutoutRootStatus removeAllObservers];
    [self.shoutoutRootPrivacy removeAllObservers];
}

- (void)applicationWillEnterForeground:(NSNotification*)notification{
    [self.shoutoutRoot observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self animateUser:snapshot.key toNewPosition:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserStatus:snapshot.key toNewStatus:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserPrivacy:snapshot.key toNewPrivacy:snapshot.value];
    }];
    [self updateMapWithLocation:self.previousLocation.coordinate];
    [self checkForNewMessages];
}

- (void)checkForNewMessages{
    PFQuery *query = [PFQuery queryWithClassName:@"Messages"];
    [query whereKey:@"to" equalTo:[PFUser currentUser]];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateMapWithLocation:(CLLocationCoordinate2D)userLocation{
    // Construct query
    [self centerMapToUserLocation];
    PFGeoPoint * geoLoc = [PFGeoPoint geoPointWithLatitude:userLocation.latitude
                                                 longitude:userLocation.longitude];
    PFQuery *query = [PFUser query];
    [query whereKey:@kParseObjectGeoKey nearGeoPoint:geoLoc withinKilometers:50];
    [query whereKey:@kParseObjectVisibleKey equalTo:[NSNumber numberWithBool:YES]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            
            NSLog(@"Successfully retrieved %lu statuses.", (unsigned long)objects.count);
            
            for (PFObject * obj in objects){
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(((PFGeoPoint *)obj[@"geo"]).latitude, ((PFGeoPoint *)obj[@"geo"]).longitude);
                NSString *title = @"Hello world!";
                if(obj[@"username"]){
                    title = obj[@"username"];
                }
                if(obj[@"displayName"]){
                    title = obj[@"displayName"];
                }
                NSString *subtitle = obj[@"status"];
                SOAnnotation *annotation = [[SOAnnotation alloc] initWithTitle:title Subtitle:subtitle Location:coordinate];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{}];
                if(obj[@"picURL"])
                    dict[@"picURL"] = obj[@"picURL"];
                if(obj[@"firstName"])
                    dict[@"firstName"] = obj[@"firstName"];
                if(obj[@"lastName"])
                    dict[@"lastName"] = obj[@"lastName"];
                if(obj[@"displayName"])
                    dict[@"displayName"] = obj[@"displayName"];
                if(obj.objectId)
                    dict[@"id"] = obj.objectId;
                annotation.userInfo = dict;
  
                if([self.markerDictionary objectForKey:[obj objectId]]){
                    [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                }
                
                if(obj[@"visible"]){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        annotation.profileImage = [UIImage imageWithData:
                                                   [NSData dataWithContentsOfURL:
                                                    [NSURL URLWithString: dict[@"picURL"]]]];
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            if([self.markerDictionary objectForKey:[obj objectId]]){
                                [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                            }
                            [self.markerDictionary setObject:annotation forKey:[obj objectId]];
                            NSLog(@"%@", [obj objectId]);
                            [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
                        });
                    });
                }
            }
            [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
            
        } else {
            // Log details of the failure
            NSLog(@"Parse error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(UIImage *)imageWithImage:(UIImage *)image borderImage:(UIImage *)borderImage covertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [borderImage drawInRect:CGRectMake( 0, 0, size.width, size.height )];
    [image drawInRect:CGRectMake( 4, 4, 40, 40)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"image created");
    return destImage;
}

#pragma mark -FirebaseEvents

- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([newMetadata[@"lat"] doubleValue], [newMetadata[@"long"] doubleValue] );
    SOAnnotation * marker = ((SOAnnotation *)self.markerDictionary[userID]);
    marker.coordinate = coordinate;
}

- (void) changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata {
    SOAnnotation *annotation = self.markerDictionary[userID];
    if(annotation){
        annotation.subtitle = newMetadata[@"status"];
//        [self.mapView deselectAnnotation:self.markerDictionary[userID] animated:NO];
//        self.mapView.selectedAnnotations = @[self.markerDictionary[userID]];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata {
//    if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
//        if(self.markerDictionary[userID] != nil){
//            [self.mapView removeAnnotation:self.markerDictionary[userID]];
//        }
//    }
//    else{
//        if(self.markerDictionary[userID] != nil){
//            [self.mapView addAnnotation:self.markerDictionary[userID]];
//        }
//        else{
//            
//        }
//    }
}

#pragma mark -LoginDelegate
-(void)promptLogin{
    if (![PFUser currentUser]) { // No user logged in
        // Create the log in view controller
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        [logInViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        
        logInViewController.facebookPermissions = @[@"email"];
        logInViewController.fields = PFLogInFieldsFacebook | PFLogInFieldsDismissButton; //Facebook login, and a Dismiss button.
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    else{
        self.statusTextView.text = [PFUser currentUser][@"status"];
    }
}

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self getFacebookInfo];
    
    UIImage * image;
    
    image = [UIImage imageWithData:
             [NSData dataWithContentsOfURL:
              [NSURL URLWithString: [PFUser currentUser][@"picURL"]]]];
    self.profilePic.image = image;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)getFacebookInfo{
    FBRequest *request = [FBRequest requestForGraphPath:@"/me?fields=id, email, picture, first_name, last_name"];
    
    //    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
    //                                  initWithGraphPath:@"/me?fields=id, email, picture, first_name, last_name"
    //                                  parameters:nil
    //                                  HTTPMethod:@"GET"];
    
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        //    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        // handle response
        if (!error) {
            // Parse the data received
            if(![PFUser currentUser][@"status"]){
                
                NSDictionary *userData = (NSDictionary *)result;
                
                NSString *facebookID = userData[@"id"];
                NSString *firstName = userData[@"first_name"];
                NSString *lastName = userData[@"last_name"];
                
                NSString *pictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200", facebookID];
                
                [[PFUser currentUser] setObject:pictureURL forKey:@"picURL"];
                [[PFUser currentUser] setObject:facebookID forKey:@"username"];
                [[PFUser currentUser] setObject:firstName forKey:@"firstName"];
                [[PFUser currentUser] setObject:lastName forKey:@"lastName"];
                [[PFUser currentUser] setObject:firstName forKey:@"displayName"];
                [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES] forKey:@"visible"];
                [PFUser currentUser][@"status"] = @"Just a man and his thoughts";
                
                CLLocation *currentLocation = self.previousLocation;
                
                if(currentLocation.coordinate.latitude != 0.0 && currentLocation.coordinate.longitude != 0.0){
                    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                                  longitude:currentLocation.coordinate.longitude];
                    [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
                }
                
                [[PFUser currentUser] saveInBackground];
            }
            
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
    NSLog(@"%@", error);
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -Button Presses

- (IBAction)shoutOutButtonPressed:(id)sender {
    [self animateSlidingView];
}

- (IBAction)doneButtonPressed:(id)sender {
    [self shoutOutButtonPressed:nil];
    [self updateStatus];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self updateStatus];
}

- (void)closeUpdateStatusView{
    if(self.shelf){
        [self animateSlidingView];
    }
}

- (void)openUpdateStatusView{
    if(!self.shelf){
        [self animateSlidingView];
    }
}

- (void)openUpdateStatusViewWithStatus:(NSString *)status{
    self.statusTextView.text = status;
    [self openUpdateStatusView];
}

- (void)updateStatus{
    if([PFUser currentUser][@"status"] != self.statusTextView.text){
        [PFUser currentUser][@"status"] = self.statusTextView.text;
        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextView.text];
        [self checkForMessage:self.statusTextView.text];
    }
    CLLocation *currentLocation = self.previousLocation;
    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                      longitude:currentLocation.coordinate.longitude];
    [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
    [[PFUser currentUser] saveInBackground];
    
    [self animateSlidingView];
    [self.statusTextView resignFirstResponder];
}

- (void)checkForMessage:(NSString *)message{
    NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:@"@"];
    [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    NSArray *array = [message componentsSeparatedByCharactersInSet:[set invertedSet]];
    for (NSString *word in array){
        if ([word hasPrefix:@"@"]) {
            PFQuery *query = [PFUser query];
            NSString *username = [word substringFromIndex:1];
            [query whereKey:@"username" equalTo:username];
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                for (PFObject *obj in objects ) {
                    PFObject *messageObj = [[PFObject alloc] initWithClassName:@"Messages"];
                    messageObj[@"from"] = [PFUser currentUser];
                    messageObj[@"to"] = obj;
                    messageObj[@"message"] = message;
                    [messageObj saveInBackground];
                }
            }];
        }
    }
}

- (void)animateSlidingView{
    [self.view layoutIfNeeded];
    if(!self.shelf){
        self.slidingViewConstraint.constant = 0;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.view layoutIfNeeded];
                             self.slidingView.alpha = 1.0;
                         }
                         completion:nil];
        [self.statusTextView becomeFirstResponder];
        self.shelf = true;
    }
    else{
        self.slidingViewConstraint.constant = -190;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.view layoutIfNeeded];
                             self.slidingView.alpha = .7;
                         }
                         completion:nil];
        self.shelf = false;
        [self.statusTextView resignFirstResponder];
    }
}

- (void)centerMapToUserLocation{
    if(self.previousLocation){
        [self.mapView setCenterCoordinate:self.previousLocation.coordinate animated:YES];
    }
}
- (IBAction)centerButtonPressed:(id)sender {
    [self centerMapToUserLocation];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
//    [self animateTextField:self.slidingView up:YES withInfo:notification.userInfo];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
//    [self animateTextField:self.slidingView up:NO withInfo:notification.userInfo];
}

- (void) animateTextField: (UIView*) view up: (BOOL) up withInfo:(NSDictionary *)userInfo
{
    const int movementDistance = 140; // tweak as needed
    NSTimeInterval movementDuration;
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&movementDuration]; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationCurve: animationCurve];
    [UIView setAnimationDuration: movementDuration];
    self.slidingView.frame = CGRectOffset(self.slidingView.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark -CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *loc = locations[0];
    if(self.previousLocation == nil){
        [self updateMapWithLocation:loc.coordinate];
    }
    if(self.previousLocation != nil && [self.previousLocation distanceFromLocation:loc] > 5000){
        [self updateMapWithLocation:loc.coordinate];
    }
    self.previousLocation = loc;
    NSLog(@"%@", loc);
    
    NSString *longitude = [NSString stringWithFormat:@"%f", loc.coordinate.longitude ];
    NSString *latitude = [NSString stringWithFormat:@"%f", loc.coordinate.latitude ];
    
    if([PFUser currentUser]){
        [[self.shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
        
        [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
        [[PFUser currentUser] saveInBackground];
    }
}

-(void)mapPanned{
    NSLog(@"map panned");
    [self.mapViewDelegate mapView:self.mapView regionIsChanging:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier  isEqual: @"openInboxSegue"]) {
        SOInboxViewController *destVC = (SOInboxViewController *)segue.destinationViewController;
        destVC.delegate = self;
    }
}

-(void)locationUpdated:(NSNotification *)notification{
    CLLocation * loc = notification.object;
    NSLog(@"%@", loc);
    if((loc.coordinate.latitude != 0.0 && loc.coordinate.longitude != 0.0)){
        if(self.previousLocation == nil){
            [self updateMapWithLocation:loc.coordinate];
        }
        if(self.previousLocation != nil && [self.previousLocation distanceFromLocation:loc] > 5000){
            [self updateMapWithLocation:loc.coordinate];
        }
        if(self.previousLocation == nil || [self.previousLocation distanceFromLocation:loc] > 10){
            self.previousLocation = loc;
            
            NSString *longitude = [NSString stringWithFormat:@"%f", loc.coordinate.longitude ];
            NSString *latitude = [NSString stringWithFormat:@"%f", loc.coordinate.latitude ];
            
            if([PFUser currentUser]){
                [[self.shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
                
                [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
                [[PFUser currentUser] saveInBackground];
                NSLog(@"network request made");
            }
        }
    }
}

@end
