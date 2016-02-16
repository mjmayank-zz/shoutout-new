//
//  AppDelegate.m
//  shoutout
//
//  Created by Mayank Jain on 9/2/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "LocationManager.h"
//#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "Shoutout-Swift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [ParseCrashReporting enable];
    
    [Parse setApplicationId:@"S5HVjNqmiwUgiGjMDiJLYh361p5P7Ob3fCOabrJ9"
                  clientKey:@"3GWNcqZ7LJhBtGbbmQfs0ROHKFM5sX6GDT9IWhCk"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        LocationManager *manager = [LocationManager sharedLocationManager];
        [manager enterBackgroundMode];
    }
    else{
        [LocationManager initLocationManager];
        [self startLocationManager];
    }
    
    BOOL hasPermissions =
    ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasPermissions"] && [PFUser currentUser]);
    
    NSString *storyboardId = hasPermissions ? @"mapVC" : @"SONUXVC";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *initViewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    
    BOOL enabled = [application isRegisteredForRemoteNotifications];
    
    BOOL willShowNUX = ![[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultShownNUXKey];
    
    if(!willShowNUX && (enabled || hasPermissions)){
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:initViewController];
    navigationController.navigationBarHidden = YES;
    [navigationController.interactivePopGestureRecognizer setDelegate:nil];
    
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[LocationManager sharedLocationManager] enterBackgroundMode];
    
    if([PFUser currentUser]) {
        if(![PFUser currentUser][@"visible"] || [PFUser currentUser][@"static"]){
            [[LocationManager sharedLocationManager] stopLocationUpdates];
        }
    }
    
    if([PFUser currentUser]){
        Firebase *shoutoutOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        [[shoutoutOnline childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@"NO"];
        [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"online"];
        [[PFUser currentUser] saveInBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[LocationManager sharedLocationManager] enterForegroundMode];
    
    if ([PFUser currentUser]) {
        if(![PFUser currentUser][@"visible"] || [PFUser currentUser][@"static"]){
            [[LocationManager sharedLocationManager] stopLocationUpdates];
        }
    }
    
    if([PFUser currentUser]){
        Firebase *shoutoutOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        [[shoutoutOnline childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@"YES"];
        [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES] forKey:@"online"];
        [[PFUser currentUser] saveInBackground];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if([PFUser currentUser]){
        Firebase *shoutoutOnline = [[Firebase alloc] initWithUrl:@"https://shoutout.firebaseio.com/online"];
        [[shoutoutOnline childByAppendingPath:[[PFUser currentUser] objectId]] setValue:@"NO"];
        [[PFUser currentUser] setObject:[NSNumber numberWithBool:NO] forKey:@"online"];
        [[PFUser currentUser] saveInBackground];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
//    return [FBSession.activeSession handleOpenURL:url];
    return YES;
}

-(void)startLocationManager{
        if([CLLocationManager locationServicesEnabled]){
            if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
                [[LocationManager sharedLocationManager] enterForegroundMode];
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
//    return [PFFacebookUtils handleOpenURL:url];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

@end
