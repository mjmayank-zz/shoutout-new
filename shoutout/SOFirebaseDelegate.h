//
//  SOFirebaseDelegate.h
//  shoutout
//
//  Created by Mayank Jain on 10/18/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
@class ViewController;

@interface SOFirebaseDelegate : NSObject

@property (strong, nonatomic) Firebase* shoutoutRoot;
@property (strong, nonatomic) Firebase* shoutoutRootStatus;
@property (strong, nonatomic) Firebase* shoutoutRootPrivacy;
@property (strong, nonatomic) Firebase* shoutoutRootOnline;

@property (weak, nonatomic) ViewController* delegate;

-(void)registerFirebaseListeners;
-(void)deregisterFirebaseListeners;

@end
