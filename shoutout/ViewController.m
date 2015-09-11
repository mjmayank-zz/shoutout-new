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

#import "ViewController.h"
#import "LocationManager.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <AudioToolbox/AudioServices.h>

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation * previousLocation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getFacebookInfo];
    
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
    
    self.mapView.delegate = self;
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
//    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
//        [self.locationManager requestAlwaysAuthorization];
//    }
    [self.locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    
    self.shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
    self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
    self.shoutoutRootPrivacy = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/privacy"];
    
    [self.shoutoutRoot observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self animateUser:snapshot.key toNewPosition:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserStatus:snapshot.key toNewStatus:snapshot.value];
    }];
    
    [self.shoutoutRootStatus observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        [self changeUserPrivacy:snapshot.key toNewPrivacy:snapshot.value];
    }];
    
    UIImage * image = [UIImage imageWithData:
             [NSData dataWithContentsOfURL:
              [NSURL URLWithString: [PFUser currentUser][@"picURL"]]]];
    self.profilePic.image = image;
    self.profilePic.layer.cornerRadius = 35.0;
    self.profilePic.layer.masksToBounds = YES;
    
    self.statusTextView.text = [PFUser currentUser][@"status"];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.saveButton.layer setCornerRadius:4.0f];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
//    [self promptLogin];
    CLLocationCoordinate2D userLocation = CLLocationCoordinate2DMake(40.1105, -88.2284);
    [self updateMapWithLocation:userLocation];
    // set the map's center coordinate
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.mapView.delegate = nil;
    [self.mapView removeFromSuperview];
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
                        UIImage *fullImage = [self imageWithImage:[UIImage imageWithData:
                                                                   [NSData dataWithContentsOfURL:
                                                                    [NSURL URLWithString: dict[@"picURL"]]]] borderImage:[UIImage imageNamed:@"background"] covertToSize:CGSizeMake(48, 56)];
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            annotation.image = fullImage;
                            annotation.profileImage = [UIImage imageWithData:
                                                       [NSData dataWithContentsOfURL:
                                                        [NSURL URLWithString: dict[@"picURL"]]]];
                            if([self.markerDictionary objectForKey:[obj objectId]]){
                                [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                            }
                            [self.markerDictionary setObject:annotation forKey:[obj objectId]];
                            NSLog(@"%@", [obj objectId]);
                            [self.mapView addAnnotation:annotation];
                        });
                    });
                }
                
            }
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark -MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
//    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    NSArray * keys = [self.markerDictionary allKeys];
    if([keys count] > 0){
        CLLocationDegrees centerLatitude = mapView.centerCoordinate.latitude;
        CLLocationDegrees centerLongitude = mapView.centerCoordinate.longitude;
        
        CLLocation * screenCenter = [[CLLocation alloc] initWithLatitude:centerLatitude longitude:centerLongitude];
        
        SOAnnotation * toShow = self.markerDictionary[keys[0]];
        
        CLLocationDistance minDistance = [screenCenter distanceFromLocation:[[CLLocation alloc] initWithLatitude:toShow.coordinate.latitude longitude:toShow.coordinate.longitude]];
        
        
        for(int i = 0; i<[keys count]; i++){
            SOAnnotation * annotation = self.markerDictionary[keys[i]];
            
            CLLocation * loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
            
            CLLocationDistance distance = [screenCenter distanceFromLocation:loc];
            
            if(distance <= minDistance){
                minDistance = distance;
                toShow = self.markerDictionary[keys[i]];
            }
            
        }
        [mapView selectAnnotation:toShow animated:YES];
    }
}

- (void)mapViewRegionIsChanging:(MKMapView *)mapView{
//    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

// Always show a callout when an annotation is tapped.
- (BOOL)mapView:(MKMapView *)mapView annotationCanShowCallout:(id <MKAnnotation>)annotation {
    return NO;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    ShoutRMMarker *marker = (ShoutRMMarker *)view;
    [marker didPressButtonWithName:@"profile"];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    ShoutRMMarker *marker = (ShoutRMMarker *)view;
    [marker didPressButtonWithName:@"profile"];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    UIImage *image = ((SOAnnotation *)annotation).profileImage;
    NSDictionary *userInfo = ((SOAnnotation *)annotation).userInfo;
    ShoutRMMarker *annotationImage = (ShoutRMMarker *)[mapView dequeueReusableAnnotationViewWithIdentifier:userInfo[@"id"]];
    
    if ( ! annotationImage)
    {
        annotationImage = [[ShoutRMMarker alloc] initWithAnnotation:annotation reuseIdentifier:userInfo[@"id"] image:image];
//        annotationImage.image = image;
        annotationImage.shout = ((SOAnnotation *)annotation).subtitle;
        annotationImage.canShowCallout = NO;
        annotationImage.enabled = YES;
        annotationImage.centerOffset = CGPointMake(0, -40);
    }
    
    return annotationImage;
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
        [self.mapView deselectAnnotation:self.markerDictionary[userID] animated:NO];
        self.mapView.selectedAnnotations = @[self.markerDictionary[userID]];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata {
    if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
        if(self.markerDictionary[userID] != nil){
            [self.mapView removeAnnotation:self.markerDictionary[userID]];
        }
    }
    else{
        if(self.markerDictionary[userID] != nil){
            [self.mapView addAnnotation:self.markerDictionary[userID]];
        }
        else{
            
        }
    }
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
                
                CLLocation *currentLocation = [[LocationManager sharedLocationManager] lastLocation];
                
                PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                                  longitude:currentLocation.coordinate.longitude];
                [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
                
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
    [self.view layoutIfNeeded];
    if(!self.shelf){
        self.slidingViewConstraint.constant = -20;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
//                             [self.slidingView setFrame:CGRectMake(self.slidingView.frame.origin.x, self.slidingView.frame.origin.y +180, self.slidingView.frame.size.width, self.slidingView.frame.size.height)];
                            [self.view layoutIfNeeded];
                             self.slidingView.alpha = 1.0;
                         }
                         completion:nil];
        [self.statusTextView becomeFirstResponder];
        self.shelf = true;
    }
    else{
        self.slidingViewConstraint.constant = -210;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
//                             [self.slidingView setFrame:CGRectMake(self.slidingView.frame.origin.x, self.slidingView.frame.origin.y -180, self.slidingView.frame.size.width, self.slidingView.frame.size.height)];
                            [self.view layoutIfNeeded];
                             self.slidingView.alpha = .7;
                         }
                         completion:nil];
        self.shelf = false;
        [self.statusTextView resignFirstResponder];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    [self shoutOutButtonPressed:nil];
//    [self saveButtonPressed:nil];
    //    [self.statusTextField resignFirstResponder];
}

- (IBAction)saveButtonPressed:(id)sender {
    [PFUser currentUser][@"status"] = self.statusTextView.text;
    [PFUser currentUser][@"visible"] = [NSNumber numberWithBool:self.privacyToggle.on];
    
    CLLocation *currentLocation = [[LocationManager sharedLocationManager] lastLocation];
    
    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                      longitude:currentLocation.coordinate.longitude];
    [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
    
    [[PFUser currentUser] saveInBackground];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    [self shoutOutButtonPressed:nil];
    [self.statusTextView resignFirstResponder];
    
    [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextView.text];
    
    if(self.privacyToggle.on){
        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"privacy" ] setValue:@"YES"];
    }
    else{
        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"privacy" ] setValue:@"NO"];
    }
}

- (void)centerMapToUserLocation{
    if(self.locationManager.location){
        self.mapView.centerCoordinate = self.locationManager.location.coordinate;
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
    if(self.previousLocation == nil || [self.previousLocation distanceFromLocation:loc] > 10){
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
}

@end
