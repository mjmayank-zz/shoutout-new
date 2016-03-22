//
//  SOComposeStatusViewController.m
//  shoutout
//
//  Created by Mayank Jain on 11/8/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//
#define kParseObjectClassKey    "StatusObject"
#define kParseObjectGeoKey      "geo"
#define kParseObjectImageKey    "imageFile"
#define kParseObjectUserKey     "user"
#define kParseObjectCaption     "caption"
#define kParseObjectVisibleKey  "visible"
#define Notification_LocationUpdate @"LocationUpdate"

#import "SOComposeStatusViewController.h"
#import "ViewController.h"
#import "Shoutout-Swift.h"

@implementation SOComposeStatusViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.shoutoutRootStatus = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/status"];
    
    PFObject *profileImageObj = [PFUser currentUser][@"profileImage"];
    if(profileImageObj){
        [profileImageObj fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            PFFile *file = profileImageObj[@"image"];
            [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                self.profilePic.image = [UIImage imageWithData:data];
            }];
        }];
    }
    
    //setup sliding view elements
    self.profilePic.layer.cornerRadius = self.profilePic.frame.size.height/2.0;
    self.profilePic.layer.masksToBounds = YES;
    self.profilePictureBorder.layer.cornerRadius = self.profilePictureBorder.frame.size.height/2.0;
    
    NSString * status = [PFUser currentUser][@"status"];
    self.statusTextView.text = status;
    self.statusTextView.delegate = self;
    if(!status || [status isEqualToString:@""]){
        [self.delegate openUpdateStatusView];
    }
    
    [self.saveButton.layer setCornerRadius:4.0f];
    [self.clusterSendButton.layer setCornerRadius:4.0f];
    
    self.clusterTextView.delegate = self;
    
    if([PFUser currentUser][@"static"]){
        self.composeSwitcher.selectedSegmentIndex = 0;
        self.composeSwitcher.hidden = NO;
    }
}

- (void)setStatusText:(NSString *)status{
    self.statusTextView.text = status;
}

- (void)updateStatus{
    if([PFUser currentUser][@"status"] != self.statusTextView.text){
        if ([self.statusTextView.text length] == 0){
            SOComposeStatusViewController *this = self;
            [PFCloud callFunctionInBackground:@"getRandomStatus" withParameters:@{} block:^(NSDictionary * object, NSError * error) {
                if (error == nil) {
                    [this updateStatus:[object objectForKey:@"status"]];
                }
            }];
        } else {
            [self updateStatus:self.statusTextView.text];
        }
    }

    [self closeUpdateStatusView];
}

-(void)updateStatus:(NSString*)status{
    if([PFUser currentUser][@"statusObj"] == nil){
        PFObject *status = [PFObject objectWithClassName:@"Status"];
        status[@"status"] = status;
        status[@"views"] = @0;
        status[@"author"] = [PFUser currentUser];
        [status saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [PFUser currentUser][@"statusObj"] = status;
                [[PFUser currentUser] saveInBackground];
            } else {
                // There was a problem, check error.description
            }
        }];
    }
    
    [[PFUser currentUser][@"statusObj"] fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [PFUser currentUser][@"statusObj"][@"status"] = status;
        [PFUser currentUser][@"statusObj"][@"views"] = @0;
        [[PFUser currentUser][@"statusObj"] saveInBackground];
    }];
    [PFUser currentUser][@"status"] = status;
    [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:status];
    [self checkForRecipients:status];
    //        [self sendClusterMessage:self.delegate.previousLocation.coordinate withMessage:self.statusTextView.text];
    [[PFUser currentUser] saveInBackground];
    [PFAnalytics trackEvent:@"updatedStatus" dimensions:nil];
    [SOBackendUtils incrementScore:5];
}

- (NSString*)replaceEmptyMessage:(NSString*)message{
    if ([message length] == 0){
        NSDictionary *object = [PFCloud callFunction:@"getRandomStatus" withParameters:@{}];
        return [object objectForKey:@"status"];
    }
    return message;
}

- (void)checkForRecipients:(NSString *)message{
    NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithCharactersInString:@"@"];
    [set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    NSArray *array = [message componentsSeparatedByCharactersInSet:[set invertedSet]];
    PFObject *messageObj = [[PFObject alloc] initWithClassName:@"Messages"];
    messageObj[@"from"] = [PFUser currentUser];
    for (NSString *word in array){
        if ([word hasPrefix:@"@"]) {
            PFQuery *query = [PFUser query];
            NSString *username = [[word substringFromIndex:1] lowercaseString];
            [query whereKey:@"username" equalTo:username];
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                for (PFObject *obj in objects ) {
                    messageObj[@"to"] = obj;
                    [messageObj addUniqueObject:obj forKey:@"toArray"];
                    messageObj[@"message"] = message;
                    messageObj[@"read"] = [NSNumber numberWithBool:NO];
                    [messageObj saveInBackground];
                    
                    // Create our Installation query
                    PFQuery *pushQuery = [PFInstallation query];
                    [pushQuery whereKey:@"user" equalTo:obj];
                    
                    NSString * fullMessage = [NSString stringWithFormat:@"%@: %@", [PFUser currentUser][@"username"], message];
                    
                    // Send push notification to query
                    NSDictionary *data = @{
                                           @"alert":fullMessage,
                                           @"badge":@"Increment",
                                           @"openToUserId":[PFUser currentUser].objectId
                                           };
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery]; // Set our Installation query
                    [push setData:data];
                    [push sendPushInBackground];
                    [SOBackendUtils incrementScore:5];
                }
            }];
        }
    }
}

- (void)sendClusterMessage:(CLLocationCoordinate2D)location withMessage:(NSString *)message{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Send message?" message:@"This will send a message to everyone within your establishment" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [PFCloud callFunctionInBackground:@"clusterMessage"
                           withParameters:@{@"lat": [NSNumber numberWithDouble:location.latitude],
                                            @"long": [NSNumber numberWithDouble:location.longitude],
                                            @"user": [PFUser currentUser].objectId,
                                            @"message":message}
                                    block:^(NSArray *objects, NSError *error) {
                                        if (!error) {
                                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Your message was sent successfully" preferredStyle:UIAlertControllerStyleAlert];
                                            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                            [alertController addAction:yesAction];
                                            [self presentViewController:alertController animated:YES completion:nil];
                                        } else {
                                            // Log details of the failure
                                            NSLog(@"Parse error: %@ %@", error, [error userInfo]);
                                            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Something went wrong. Try again later or send us an email at team@getshoutout.co" preferredStyle:UIAlertControllerStyleAlert];
                                            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                            [alertController addAction:yesAction];
                                            [self presentViewController:alertController animated:YES completion:nil];
                                        }
                                    }];
    }];
    [alertController addAction:yesAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)openUpdateStatusView{
    [self.statusTextView becomeFirstResponder];
}

- (void)closeUpdateStatusView{
    [self.delegate closeUpdateStatusView];
    [self.statusTextView resignFirstResponder];
    [self.clusterTextView resignFirstResponder];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self closeUpdateStatusView];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self updateStatus];
}
- (IBAction)clusterSendButtonPressed:(id)sender {
    [self sendClusterMessage:self.delegate.previousLocation.coordinate withMessage:self.clusterTextView.text];
}
- (IBAction)composerTypeSwitched:(id)sender {
    UISegmentedControl *switcher = (UISegmentedControl *)sender;
    if(switcher.selectedSegmentIndex == 0){
        self.clusterContainerView.hidden = YES;
        self.statusContainerView.hidden = NO;
        [self.statusTextView becomeFirstResponder];
    }
    else{
        self.clusterContainerView.hidden = NO;
        self.statusContainerView.hidden = YES;
        [self.clusterTextView becomeFirstResponder];
    }
}

#pragma mark -UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView{
    self.statusCharacterCount.text = [NSString stringWithFormat:@"%lu/120", (unsigned long)[textView.text length]];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        if(self.composeSwitcher.selectedSegmentIndex == 0){
            [self updateStatus];
        }
        return NO;
    }
    if(range.length + range.location > textView.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return newLength <= 120;
}

@end
