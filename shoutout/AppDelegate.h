//
//  AppDelegate.h
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocationKit/LocationKit.h>
#import <Firebase/Firebase.h>
@import CoreMotion;

@interface AppDelegate : UIResponder <UIApplicationDelegate, LocationKitDelegate>

@property (strong, nonatomic) UIWindow *window;

-(void)startLocationKit;

@end

