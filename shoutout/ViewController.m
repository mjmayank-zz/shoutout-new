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
//#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <AudioToolbox/AudioServices.h>
#import "Shoutout-Swift.h"

@interface ViewController ()

@property (assign, nonatomic) int *count;
@property (strong, nonatomic) IBOutlet UIButton *cancelStatusButton;
@property (strong, nonatomic) IBOutlet UIView *profilePictureBorder;
@property (strong, nonatomic) SOListViewController *listViewVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.count = 0;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasPermissions"];
    
    self.markerDictionary = [[NSMutableDictionary alloc] init];
    
    [[PFUser currentUser] fetchInBackground];
    
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
    
    self.mapView.delegate = self.mapViewDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];

    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    pinchGesture.delegate = self;
    [self.mapView addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned)];
    panGesture.delegate = self;
    [self.mapView addGestureRecognizer:panGesture];
    
    for (CALayer *subLayer in self.listViewContainer.layer.sublayers)
    {
        subLayer.cornerRadius = 10;
        subLayer.masksToBounds = YES;
    }
    
    [self registerNotifications];
    
    self.shoutoutRoot = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/loc"];
    self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
    self.shoutoutRootPrivacy = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/privacy"];
    self.shoutoutRootOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
    [self registerFirebaseListeners];
    
    PFObject *profileImageObj = [PFUser currentUser][@"profileImage"];
    if(profileImageObj){
        [profileImageObj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            PFFile *file = profileImageObj[@"image"];
            [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                self.profilePic.image = [UIImage imageWithData:data];
            }];
        }];
    }
    else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage * image = [UIImage imageWithData:
                               [NSData dataWithContentsOfURL:
                                [NSURL URLWithString: [PFUser currentUser][@"picURL"]]]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                if(image){
                    self.profilePic.image = image;
                }
            });
        });
    }
    
    //setup sliding view elements
    self.profilePic.layer.cornerRadius = self.profilePic.frame.size.height/2.0;
    self.profilePic.layer.masksToBounds = YES;
    self.profilePictureBorder.layer.cornerRadius = self.profilePictureBorder.frame.size.height/2.0;
    
    NSString * status = [PFUser currentUser][@"status"];
    self.statusTextView.text = status;
    self.statusTextView.delegate = self;
    if(!status || [status isEqualToString:@""]){
        [self openUpdateStatusView];
    }
    
    [self.saveButton.layer setCornerRadius:4.0f];
    [self.cancelStatusButton.layer setCornerRadius:self.cancelStatusButton.frame.size.height/2];
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(closeUpdateStatusView)];
    [self.slidingView addGestureRecognizer:singleFingerTap];
    
    //set up mailbox
    [self.unreadIndicator.layer setCornerRadius:self.unreadIndicator.frame.size.height/2];
    self.unreadIndicator.layer.masksToBounds = YES;
    
    CLLocationCoordinate2D userLocation = CLLocationCoordinate2DMake(40.1105, -88.2284);
    [self updateMapWithLocation:userLocation];
    // set the map's center coordinate
    
    // Associate the device with a user
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"user"] = [PFUser currentUser];
    [installation saveInBackground];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self checkForNewMessages];
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
    [self registerFirebaseListeners];
    [self updateMapWithLocation:self.previousLocation.coordinate];
    [self checkForNewMessages];
}

- (void)didReceiveMemoryWarning {  
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerNotifications{
    CLLocation * locationInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationUpdated:) name:
     Notification_LocationUpdate object:locationInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterBackground:) name:
     UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:
     UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replyNotificationReceived:) name:
     @"replyToShout" object:nil];
}

- (void)unregisterNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:Notification_LocationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"replyToShout" object:nil];
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

- (void) updateMapWithLocation:(CLLocationCoordinate2D)userLocation{
    // Construct query
    [self centerMapToUserLocation];
    PFGeoPoint * geoLoc = [PFGeoPoint geoPointWithLatitude:userLocation.latitude
                                                 longitude:userLocation.longitude];
    PFQuery *query = [PFUser query];
    [query whereKey:@kParseObjectGeoKey nearGeoPoint:geoLoc withinKilometers:50];
    [query whereKey:@kParseObjectVisibleKey equalTo:[NSNumber numberWithBool:YES]];
    [query includeKey:@"profileImage"];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            
            NSLog(@"Successfully retrieved %lu statuses.", (unsigned long)objects.count);
            
            for (PFObject * obj in objects){
                if([self.markerDictionary objectForKey:[obj objectId]]){
                    [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                }
                
                [self addUserToAnnotationDictionary:obj];
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
    NSString *title = @"Hello world!";
    if(obj[@"username"]){
        title = obj[@"username"];
    }
    NSString *subtitle = obj[@"status"];
    SOAnnotation *annotation = [[SOAnnotation alloc] initWithTitle:title Subtitle:subtitle Location:coordinate];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{}];
    if(obj[@"username"])
        dict[@"username"] = obj[@"username"];
    if(obj[@"picURL"])
        dict[@"picURL"] = obj[@"picURL"];
    if(obj.objectId)
        dict[@"id"] = obj.objectId;
    if(obj.updatedAt)
        dict[@"updatedAt"] = obj.updatedAt;
    annotation.userInfo = dict;
    annotation.online = [obj[@"online"] boolValue];
    
    if(obj[@"visible"]){
        if(obj[@"profileImage"]){
            [obj[@"profileImage"] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                PFFile *file = obj[@"profileImage"][@"image"];
                [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                    annotation.profileImage = [UIImage imageWithData:data];
                }];
                
                if([self.markerDictionary objectForKey:[obj objectId]]){
                    [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                }
                [self.markerDictionary setObject:annotation forKey:[obj objectId]];
                [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
            }];
        }
        else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                annotation.profileImage = [UIImage imageWithData:
                                           [NSData dataWithContentsOfURL:
                                            [NSURL URLWithString: dict[@"picURL"]]]];
                dispatch_async(dispatch_get_main_queue(), ^(){
                    if([self.markerDictionary objectForKey:[obj objectId]]){
                        [self.mapView removeAnnotation:[self.markerDictionary objectForKey:[obj objectId]]];
                    }
                    [self.markerDictionary setObject:annotation forKey:[obj objectId]];
                    [self.mapViewDelegate.clusteringController setAnnotations:[self.markerDictionary allValues]];
                });
            });
        }
        
    }
}

#pragma mark -FirebaseEvents

- (void) animateUser:(NSString *)userID toNewPosition:(NSDictionary *)newMetadata {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([newMetadata[@"lat"] doubleValue], [newMetadata[@"long"] doubleValue] );
    SOAnnotation * annotation = ((SOAnnotation *)self.markerDictionary[userID]);
    KPAnnotation * clusterAnnotation = [self.mapViewDelegate.clusteringController getClusterForAnnotation:annotation];
    if(annotation){
        annotation.coordinate = coordinate;
    }
    if(clusterAnnotation){
        if(![clusterAnnotation isCluster]){
            clusterAnnotation.coordinate = coordinate;
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

    if(annotation && ![clusterAnnotation isCluster]){
        if([((NSString *)newMetadata[@"privacy"]) isEqualToString:@"NO"]){
            [self.mapView removeAnnotation:clusterAnnotation];
        }
    }
    else{

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

- (IBAction)cancelButtonPressed:(id)sender {
    [self closeUpdateStatusView];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self updateStatus];
}

- (void)centerMapToUserLocation{
    if(self.previousLocation){
        [self.mapView setCenterCoordinate:self.previousLocation.coordinate animated:YES];
    }
    else{
        
    }
}

- (IBAction)listViewButtonPressed:(id)sender {
    [self.view layoutIfNeeded];
    if(self.listViewContainerConstraint.constant != 0){
        self.listViewContainerConstraint.constant = 0;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.view layoutIfNeeded];
                         }
                         completion:nil];
    }
    else{
        self.listViewContainerConstraint.constant = -300;
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.view layoutIfNeeded];
                         }
                         completion:nil];
    }
}

- (IBAction)centerButtonPressed:(id)sender {
    [self centerMapToUserLocation];
    [PFAnalytics trackEvent:@"pressedLocateButton" dimensions:nil];
}

#pragma -mark Update Status View

- (void)closeUpdateStatusView{
    [self.view layoutIfNeeded];
    self.slidingViewConstraint.constant = -450;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
    [self.statusTextView resignFirstResponder];
}

- (void)openUpdateStatusView{
    [self.view layoutIfNeeded];
    self.slidingViewConstraint.constant = 0;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
    [self.statusTextView becomeFirstResponder];
    [PFAnalytics trackEvent:@"openedComposeView" dimensions:nil];
}

- (void)openUpdateStatusViewWithStatus:(NSString *)status{
    self.statusTextView.text = status;
    [self openUpdateStatusView];
    [PFAnalytics trackEvent:@"openedComposeView" dimensions:@{@"status":status}];
}

- (void)updateStatus{
    if([PFUser currentUser][@"status"] != self.statusTextView.text){
        [PFUser currentUser][@"status"] = self.statusTextView.text;
        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextView.text];
        [self checkForRecipients:self.statusTextView.text];
        [PFAnalytics trackEvent:@"updatedStatus" dimensions:nil];
    }
    CLLocation *currentLocation = self.previousLocation;
    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                      longitude:currentLocation.coordinate.longitude];
    [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
    [[PFUser currentUser] saveInBackground];
    
    [self closeUpdateStatusView];
    [self.statusTextView resignFirstResponder];
}

- (void)checkForRecipients:(NSString *)message{
    NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:@"@"];
    [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    NSArray *array = [message componentsSeparatedByCharactersInSet:[set invertedSet]];
    for (NSString *word in array){
        if ([word hasPrefix:@"@"]) {
            PFQuery *query = [PFUser query];
            NSString *username = [[word substringFromIndex:1] lowercaseString];
            [query whereKey:@"username" equalTo:username];
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                for (PFObject *obj in objects ) {
                    PFObject *messageObj = [[PFObject alloc] initWithClassName:@"Messages"];
                    messageObj[@"from"] = [PFUser currentUser];
                    messageObj[@"to"] = obj;
                    messageObj[@"message"] = message;
                    messageObj[@"read"] = [NSNumber numberWithBool:NO];
                    [messageObj saveInBackground];
                    
                    // Create our Installation query
                    PFQuery *pushQuery = [PFInstallation query];
                    [pushQuery whereKey:@"user" equalTo:obj];
                    
                    NSString * fullMessage = [NSString stringWithFormat:@"%@: %@", [PFUser currentUser][@"username"], message];
                    
                    // Send push notification to query
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery]; // Set our Installation query
                    [push setMessage:fullMessage];
                    [push sendPushInBackground];
                }
            }];
        }
    }
}

- (void)animateSlidingView{
    if(self.slidingViewConstraint.constant != 0){
        [self openUpdateStatusView];
    }
    else{
        [self closeUpdateStatusView];
    }
}

#pragma -mark Notification Events

- (void)keyboardWillShow:(NSNotification *)notification
{

}

- (void)keyboardWillHide:(NSNotification *)notification
{

}

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
    if ([segue.identifier  isEqual: @"openInboxSegue"]) {
        SOInboxViewController *destVC = (SOInboxViewController *)segue.destinationViewController;
        destVC.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"openSettingsSegue"]) {
        ((SOSettingsViewController*)segue.destinationViewController).oldVC = self;
    }
    else if([segue.identifier isEqualToString:@"listViewController"]){
        self.listViewVC = segue.destinationViewController;
    }
}

#pragma mark -UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView{
    self.statusCharacterCount.text = [NSString stringWithFormat:@"%lu/120", [textView.text length]];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [self updateStatus];
        return NO;
    }
    else if([textView.text length] >= 120){
        return NO;
    }
    
    return YES;
}

#pragma mark -CLLocationManagerDelegate
//LocationManager
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *loc = [locations lastObject];
    [self updateUserLocation:loc];
}

-(void)locationUpdated:(NSNotification *)notification{
    CLLocation * loc = notification.object;
    [self updateUserLocation:loc];
}

- (void)updateUserLocation:(CLLocation *)loc{
    NSLog(@"%@", loc);
    if((loc.coordinate.latitude != 0.0 && loc.coordinate.longitude != 0.0)){
        [PFUser currentUser][@"geo"] = [PFGeoPoint geoPointWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
        if(self.previousLocation == nil){
            [self updateMapWithLocation:loc.coordinate];
        }
        else if([self.previousLocation distanceFromLocation:loc] > 5000){
            [self updateMapWithLocation:loc.coordinate];
        }
        if(self.previousLocation == nil || [self.previousLocation distanceFromLocation:loc] > 10){
            self.previousLocation = loc;
            
            NSString *longitude = [NSString stringWithFormat:@"%f", loc.coordinate.longitude ];
            NSString *latitude = [NSString stringWithFormat:@"%f", loc.coordinate.latitude ];
            
            if([PFUser currentUser]){
                if(![self.markerDictionary objectForKey:[[PFUser currentUser] objectId]]){
                    [self addUserToAnnotationDictionary:[PFUser currentUser]];
                }
                else{
                    SOAnnotation *annotation = [self.markerDictionary objectForKey:[[PFUser currentUser] objectId]];
                    annotation.coordinate = loc.coordinate;
                }
                
                [[self.shoutoutRoot childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@{@"lat": latitude, @"long": longitude}];
                
                [[PFUser currentUser] saveInBackground];
                NSLog(@"network request made");
            }
        }
    }
}

@end
