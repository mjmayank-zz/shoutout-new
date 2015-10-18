//
//  SOComposeStatusView.m
//  shoutout
//
//  Created by Mayank Jain on 10/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#define kParseObjectClassKey    "StatusObject"
#define kParseObjectGeoKey      "geo"
#define kParseObjectImageKey    "imageFile"
#define kParseObjectUserKey     "user"
#define kParseObjectCaption     "caption"
#define kParseObjectVisibleKey  "visible"

#import "SOComposeStatusView.h"
#import "ViewController.h"

@implementation SOComposeStatusView

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        self.profilePic.layer.cornerRadius = self.profilePic.frame.size.height/2.0;
        self.profilePic.layer.masksToBounds = YES;
        self.profilePictureBorder.layer.cornerRadius = self.profilePictureBorder.frame.size.height/2.0;
        
        self.statusTextView.text = [PFUser currentUser][@"status"];
        
        [self.saveButton.layer setCornerRadius:4.0f];
        [self.cancelStatusButton.layer setCornerRadius:self.cancelStatusButton.frame.size.height/2];
    }
    return self;
}

- (void)updateStatus{
    if([PFUser currentUser][@"status"] != self.statusTextView.text){
        [PFUser currentUser][@"status"] = self.statusTextView.text;
        [[[self.delegate.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextView.text];
        [self checkForRecipients:self.statusTextView.text];
    }
    CLLocation *currentLocation = self.delegate.previousLocation;
    PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude
                                                      longitude:currentLocation.coordinate.longitude];
    [[PFUser currentUser] setObject:currentPoint forKey:@kParseObjectGeoKey];
    [[PFUser currentUser] saveInBackground];
    
    [self.delegate closeUpdateStatusView];
    [self.statusTextView resignFirstResponder];
}

- (void)checkForRecipients:(NSString *)message{
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

- (IBAction)cancelButtonPressed:(id)sender {
    [self.delegate closeUpdateStatusView];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self updateStatus];
}

@end
