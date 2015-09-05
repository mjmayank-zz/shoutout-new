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

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.markerDictionary = [[NSMutableDictionary alloc] init];
    self.markerArray = [[NSMutableArray alloc] init];
    self.statusArray = [[NSMutableArray alloc] init];
    
    // initialize the map view
    self.mapView = [[MGLMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // set the map's center coordinate
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(40.1105, -88.2284)
                            zoomLevel:15
                             animated:NO];
    [self.view insertSubview:self.mapView belowSubview:self.slidingView];
    
    self.mapView.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    // Create a PFGeoPoint using the current location (to use in our query)
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    CLLocation * locationInfo;
    [nc addObserver:self selector:@selector(locationDidUpdate:) name:@"LocationUpdate" object:locationInfo];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:
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
    
    self.statusTextView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.saveButton.layer setCornerRadius:4.0f];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self promptLogin];
    PFGeoPoint *userLocation =
    [PFGeoPoint geoPointWithLatitude:40.1105
                           longitude:-88.2284];
    [self updateMapWithLocation:userLocation];
    // set the map's center coordinate
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
        
        logInViewController.facebookPermissions = @[@"email",@"user_about_me", @"user_birthday"];
        logInViewController.fields = PFLogInFieldsFacebook | PFLogInFieldsDismissButton; //Facebook login, and a Dismiss button.
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    else{
        self.statusTextView.text = [PFUser currentUser][@"status"];
    }
}

- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata {
    ((SOAnnotation *)self.markerDictionary[userID]).coordinate = CLLocationCoordinate2DMake([newMetadata[@"lat"] floatValue], [newMetadata[@"long"] floatValue] );
}

- (void) updateMapWithLocation:(PFGeoPoint *)userLocation{
    // Construct query
    PFQuery *query = [PFUser query];
    [query whereKey:@kParseObjectGeoKey nearGeoPoint:userLocation withinKilometers:50000];
    [query whereKey:@kParseObjectVisibleKey equalTo:[NSNumber numberWithBool:YES]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            
            NSLog(@"Successfully retrieved %lu statuses.", (unsigned long)objects.count);
            
            for (PFObject * obj in objects){
                SOAnnotation *annotation = [[SOAnnotation alloc] init];
                annotation.coordinate = CLLocationCoordinate2DMake(((PFGeoPoint *)obj[@"geo"]).latitude, ((PFGeoPoint *)obj[@"geo"]).longitude);
                annotation.title = @"Hello world!";
                if(obj[@"displayName"]){
                    annotation.title = obj[@"displayName"];
                }
                annotation.subtitle = obj[@"status"];
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
//                annotation.anchorPoint = CGPointMake(24, 56);
                
                [self.markerArray addObject:annotation];
                [self.statusArray addObject:obj];
                
                if([self.markerDictionary objectForKey:[obj objectId]]){
                    [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                }
                
                if(obj[@"visible"]){
                    NSLog(@"%@", [obj objectId]);
                    [self.markerDictionary setObject:annotation forKey:[obj objectId]];
//                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        UIImage *fullImage = [self imageWithImage:[UIImage imageWithData:
                                                                   [NSData dataWithContentsOfURL:
                                                                    [NSURL URLWithString: dict[@"picURL"]]]] borderImage:[UIImage imageNamed:@"background"] covertToSize:CGSizeMake(48, 56)];
                        annotation.image = fullImage;
//                        dispatch_async(dispatch_get_main_queue(), ^(){
                                [self.mapView addAnnotation:annotation];
//                        });
//                    });
                }
                
            }
            
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)mapView:(MGLMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

- (void)mapViewRegionIsChanging:(MGLMapView *)mapView{
    NSLog(@"%f, %f", mapView.centerCoordinate.latitude, mapView.centerCoordinate.longitude);
}

// Always show a callout when an annotation is tapped.
- (BOOL)mapView:(MGLMapView *)mapView annotationCanShowCallout:(id <MGLAnnotation>)annotation {
    return YES;
}

- (MGLAnnotationImage *)mapView:(MGLMapView *)mapView imageForAnnotation:(id <MGLAnnotation>)annotation
{
    UIImage *image = ((SOAnnotation *)annotation).image;
    NSDictionary *userInfo = ((SOAnnotation *)annotation).userInfo;
    MGLAnnotationImage *annotationImage = [mapView dequeueReusableAnnotationImageWithIdentifier:userInfo[@"id"]];
    
    if ( ! annotationImage)
    {
        annotationImage = [MGLAnnotationImage annotationImageWithImage:image reuseIdentifier:userInfo[@"id"]];
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

- (void) changeUserStatus:(NSString *)userID toNewStatus:(NSDictionary *)newMetadata {
    ((SOAnnotation *)self.markerDictionary[userID]).title = newMetadata[@"status"];
    [self.mapView deselectAnnotation:((SOAnnotation *)self.markerDictionary[userID]) animated:NO];
    self.mapView.selectedAnnotations = @[((SOAnnotation *)self.markerDictionary[userID])];
}

- (void) changeUserPrivacy:(NSString *)userID toNewPrivacy:(NSDictionary *)newMetadata {
    if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
        if(((SOAnnotation *)self.markerDictionary[userID]) != nil){
            [self.mapView removeAnnotation:((SOAnnotation *)self.markerDictionary[userID])];
        }
    }
    else{
        if(((SOAnnotation *)self.markerDictionary[userID]) != nil){
            [self.mapView addAnnotation:((SOAnnotation *)self.markerDictionary[userID])];
        }
        else{
            
        }
    }
}

#pragma mark -LoginDelegate

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
    // Send request to Facebook
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/me?fields=id, email, picture, first_name, last_name"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
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
    
    UIImage * image;
    
    image = [UIImage imageWithData:
             [NSData dataWithContentsOfURL:
              [NSURL URLWithString: [PFUser currentUser][@"picURL"]]]];
    self.profilePic.image = image;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
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
    
    if(!self.shelf){
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.slidingView setFrame:CGRectMake(self.slidingView.frame.origin.x, self.slidingView.frame.origin.y -170, self.slidingView.frame.size.width, self.slidingView.frame.size.height)];
                             self.slidingView.alpha = 1.0;
                         }
                         completion:nil];
        self.shelf = true;
    }
    else{
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.slidingView setFrame:CGRectMake(self.slidingView.frame.origin.x, self.slidingView.frame.origin.y +170, self.slidingView.frame.size.width, self.slidingView.frame.size.height)];
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
    
//    [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextField.text];
//    
//    if(self.privacyToggle.on){
//        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"privacy" ] setValue:@"YES"];
//    }
//    else{
//        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"privacy" ] setValue:@"NO"];
//    }
//    
//    PFGeoPoint *currentCenter = [PFGeoPoint geoPointWithLatitude:mapViewR.centerCoordinate.latitude longitude:mapViewR.centerCoordinate.longitude];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    [self animateTextField:self.slidingView up:YES withInfo:notification.userInfo];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self animateTextField:self.slidingView up:NO withInfo:notification.userInfo];
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
    view.frame = CGRectOffset(view.frame, 0, movement);
    [UIView commitAnimations];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *loc = locations[0];
    
    NSString *longitude = [NSString stringWithFormat:@"%f", loc.coordinate.longitude ];
    NSString *latitude = [NSString stringWithFormat:@"%f", loc.coordinate.latitude ];
    
    if([PFUser currentUser]){
        [[self.shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
        
        [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
    }
}

-(void)locationDidUpdate:(NSNotification *)notification{
    NSLog(@"test");
    CLLocation * location = notification.object;
    
    NSString *longitude = [NSString stringWithFormat:@"%f", location.coordinate.longitude ];
    NSString *latitude = [NSString stringWithFormat:@"%f", location.coordinate.latitude ];

    if([PFUser currentUser]){
        [[self.shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
        
        [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    }
}

@end
