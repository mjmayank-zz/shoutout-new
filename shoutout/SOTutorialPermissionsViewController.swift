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
        
        updateNextButtonIfNecessary()
        self.setNeedsStatusBarAppearanceUpdate()
        
        if( NSUserDefaults.standardUserDefaults().boolForKey("hasPermissions")){
            self.performSegueWithIdentifier("permissionsToMap", sender: self)
        }
    }
    
    func updateNextButtonIfNecessary() {
        if (requestedLocation && requestedMap && !nextButton.enabled) {
            nextButton.enabled = true
            nextButton.backgroundColor = UIColor(red: 0.0392, green: 0.8824, blue: 0.7373, alpha: 1.0)
        }
        if (requestedLocation) {
            locationSwitch.on = true
        }
        if (requestedMap) {
            mapSwitch.on = true
        }
    }
    
    @IBAction func locationPermissionButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedLocation) {
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
            locationSwitch.on = true
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            if(status == .AuthorizedWhenInUse){
                LocationManager.sharedLocationManager().startLocationUpdates();
                requestedLocation = true
            }
            else if(status == .AuthorizedAlways){
                PFAnalytics.trackEvent("allowedLocation", dimensions:nil);
                requestedLocation = true
                LocationManager.sharedLocationManager().startLocationUpdates();
            }
            else{
                PFAnalytics.trackEvent("deniedLocation", dimensions:nil);
            }
            updateNextButtonIfNecessary()
    }
    
    @IBAction func mapPermissionButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedMap) {
            requestedMap = true
            PFAnalytics.trackEvent("allowedMap", dimensions:nil);
            updateNextButtonIfNecessary()
        }
        else{
            let alert = UIAlertController(title: "Your location is required initially for Shoutout to work", message: "You can remove yourself from the map on the settings menu", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                // Do nothing
            })
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
            mapSwitch.on = true
        }
    }
    
    @IBAction func pushNotificationsButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedPush) {
            let application = UIApplication.sharedApplication();
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            requestedPush = true
            PFAnalytics.trackEvent("allowedPush", dimensions:nil);
        }
    }
    
    @IBAction func didPressBackButton() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}