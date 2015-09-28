//
//  AppDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "LocationManager.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [Parse setApplicationId:@"S5HVjNqmiwUgiGjMDiJLYh361p5P7Ob3fCOabrJ9"
                  clientKey:@"3GWNcqZ7LJhBtGbbmQfs0ROHKFM5sX6GDT9IWhCk"];
    
    [PFFacebookUtils initializeFacebook];
    
    [LocationManager initLocationManager];
    
    [self startLocationKit];
    
    BOOL hasPermissions =
    ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasPermissions"] && [PFUser currentUser]);
    
    NSString *storyboardId = hasPermissions ? @"mapVC" : @"welcomeVC";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = initViewController;
    [self.window makeKeyAndVisible];
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    LKSetting *setting = [[LKSetting alloc] initWithType:LKSettingTypeLow];
    [[LocationKit sharedInstance] setOperationMode:setting];
    
    if([PFUser currentUser]){
        Firebase *shoutoutOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        [[shoutoutOnline childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@"NO"];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    LKSetting *setting = [[LKSetting alloc] initWithType:LKSettingTypeAuto];
    [[LocationKit sharedInstance] setOperationMode:setting];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
    
    if([PFUser currentUser]){
        Firebase *shoutoutOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        [[shoutoutOnline childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@"YES"];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [FBSession.activeSession handleOpenURL:url];
}

-(void)startLocationKit{
    if([CLLocationManager locationServicesEnabled]){
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
            CMMotionManager *manager = [[CMMotionManager alloc] init];
            if(manager.deviceMotionAvailable){
                NSDictionary *options = @{LKOptionUseiOSMotionActivity: @YES};
                [[LocationKit sharedInstance] startWithApiToken:@"0961455db144c71c" delegate:self options:options];
            }
            else{
                [[LocationKit sharedInstance] startWithApiToken:@"0961455db144c71c" delegate:self];
            }
//            LKSetting *setting = [[LKSetting alloc] initWithType:LKSettingTypeHigh];
//            [[LocationKit sharedInstance] applyOperationMode:setting];
        }
        else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
            NSDictionary *options = @{LKOptionWhenInUseOnly: @YES};
            [[LocationKit sharedInstance] startWithApiToken:@"0961455db144c71c" delegate:self options:options];
        }
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
//    BOOL fb = [[FBSDKApplicationDelegate sharedInstance] application:application
//                                                          openURL:url
//                                                sourceApplication:sourceApplication
//                                                       annotation:annotation];
    return [PFFacebookUtils handleOpenURL:url];
}

- (void)locationKit:(LocationKit *)locationKit didUpdateLocation:(CLLocation *)location{
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_LocationUpdate object:location];
}

- (void)locationKit:(LocationKit *)locationKit didStartVisit:(LKVisit *)visit{
    
}

@end
