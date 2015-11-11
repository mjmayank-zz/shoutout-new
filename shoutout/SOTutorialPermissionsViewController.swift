//
//  TutorialPermissionsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/10/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreMotion

class SOTutorialPermissionsViewController: UIViewController, CLLocationManagerDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate{
    
    @IBOutlet var nextButton: UIButton!
    
    @IBOutlet var mapSwitch: UISwitch!
    @IBOutlet var pushSwitch: UISwitch!
    @IBOutlet var locationSwitch: UISwitch!
    let locationManager = CLLocationManager();
    
    var requestedLocation = false
    var requestedMap = false
    var requestedPush = false
    
    override func viewDidLoad(){
        super.viewDidLoad();
        
        locationManager.delegate = self;
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if(authorizationStatus == .AuthorizedAlways || authorizationStatus == .AuthorizedWhenInUse){
            requestedLocation = true
        }
        
        let application = UIApplication.sharedApplication()
        requestedPush = application.isRegisteredForRemoteNotifications()

        updateNextButtonIfNecessary()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func updateNextButtonIfNecessary() {
        if (requestedLocation && requestedMap && !nextButton.enabled) {
            nextButton.enabled = true
            nextButton.backgroundColor = UIColor(red: 0.0392, green: 0.8824, blue: 0.7373, alpha: 1.0)
        } else {
            nextButton.enabled = false;
            nextButton.backgroundColor = UIColor(red: 0.7676, green: 0.7676, blue: 0.7676, alpha: 1.0)
        }
        locationSwitch.on = requestedLocation;
        mapSwitch.on = requestedMap;
        pushSwitch.on = requestedPush;
    }
    
    @IBAction func locationPermissionButtonPressed(sender: UISwitch) {
        if (sender.on) {
            locationManager.requestAlwaysAuthorization();
            requestedLocation = true
        }
        else{
            let alert = UIAlertController(title: "Your location is required for Shoutout to work", message: "You can disable this from the settings menu", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                // Do nothing
            })
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        sender.enabled = false
        updateNextButtonIfNecessary()
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            if(status == .AuthorizedWhenInUse){
                LocationManager.sharedLocationManager().startLocationUpdates();
                requestedLocation = true
                locationSwitch.enabled = false
            }
            else if(status == .AuthorizedAlways){
                PFAnalytics.trackEvent("allowedLocation", dimensions:nil);
                requestedLocation = true
                LocationManager.sharedLocationManager().startLocationUpdates();
                locationSwitch.enabled = false
            }
            else if(status != .NotDetermined){
                requestedLocation = false
                if (locationSwitch.enabled == false) {
                    let alert = UIAlertController(title: "Your location is required for Shoutout to work", message: "You can disable this from the settings menu", preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    let defaultAction = UIAlertAction(title: "Settings", style: .Default, handler: { (UIAlertAction) -> Void in
                        // Do nothing
                        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                    })
                    alert.addAction(cancelAction)
                    alert.addAction(defaultAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                PFAnalytics.trackEvent("deniedLocation", dimensions:nil);
                locationSwitch.enabled = false
            }
            updateNextButtonIfNecessary()
    }
    
    @IBAction func mapPermissionButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedMap) {
            let alertController = UIAlertController(title: "Shoutout will take your location and share it on the map for other users to see, even after you close the app.", message: "You can disable location services in the settings menu.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (alert:UIAlertAction) -> Void in
                sender.on = false
            })
            
            let okayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert:UIAlertAction) -> Void in
                self.requestedMap = true
                PFAnalytics.trackEvent("allowedMap", dimensions:nil);
                self.updateNextButtonIfNecessary()
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(okayAction);
            
            self.presentViewController(alertController, animated: true, completion: nil);
        }
        else{
            let alert = UIAlertController(title: "Shoutout needs your location to work.", message: "You can remove yourself from the map on the settings menu", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                // Do nothing
                self.requestedMap = false
                self.updateNextButtonIfNecessary()
            })
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func pushNotificationsButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedPush) {
            sender.enabled = false;
            let application = UIApplication.sharedApplication();
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            PFAnalytics.trackEvent("allowedPush", dimensions:nil);
        }
        
        let application = UIApplication.sharedApplication()
        requestedPush = application.isRegisteredForRemoteNotifications()
        pushSwitch.on = requestedPush;
    }
    
    @IBAction func didPressBackButton() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}