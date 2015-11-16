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
        [self.delegate openUpdateStatusView];
    }
    
    [self.saveButton.layer setCornerRadius:4.0f];
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(closeUpdateStatusView)];
    [self.backgroundView addGestureRecognizer:singleFingerTap];
}

- (void)setStatusText:(NSString *)status{
    self.statusTextView.text = status;
}

- (void)updateStatus{
    if([PFUser currentUser][@"status"] != self.statusTextView.text){
        [PFUser currentUser][@"status"] = self.statusTextView.text;
        [[[self.shoutoutRootStatus childByAppendingPath:[[PFUser currentUser] objectId]] childByAppendingPath:@"status" ] setValue:self.statusTextView.text];
        [self checkForRecipients:self.statusTextView.text];
        [PFAnalytics trackEvent:@"updatedStatus" dimensions:nil];
    }

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
                    NSDictionary *data = @{
                                           @"alert":fullMessage,
                                           @"badge":@"Increment"
                                           };
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery]; // Set our Installation query
                    [push setData:data];
                    [push sendPushInBackground];
                }
            }];
        }
    }
}

- (void)openUpdateStatusView{
    [self.statusTextView becomeFirstResponder];
}

- (void)closeUpdateStatusView{
    [self.delegate closeUpdateStatusView];
    [self.statusTextView resignFirstResponder];
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self closeUpdateStatusView];
}

- (IBAction)saveButtonPressed:(id)sender {
    [self updateStatus];
}

#pragma mark -UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView{
    self.statusCharacterCount.text = [NSString stringWithFormat:@"%lu/120", (unsigned long)[textView.text length]];
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

@end
