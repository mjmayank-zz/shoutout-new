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
    
    @IBOutlet var locationSwitch: UISwitch!
    let locationManager = CLLocationManager();
    
    var requestedLocation = false
    var requestedMotion = false
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
    }
    
    func updateNextButtonIfNecessary() {
        if (requestedLocation && !nextButton.enabled) {
            nextButton.enabled = true
            nextButton.backgroundColor = UIColor(red: 0.0392, green: 0.8824, blue: 0.7373, alpha: 1.0)
        }
        if (requestedLocation) {
            locationSwitch.on = true
            locationSwitch.userInteractionEnabled = false
        }
    }
    
    @IBAction func locationPermissionButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedLocation) {
            locationManager.requestAlwaysAuthorization();
            requestedLocation = true
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            if(status == .AuthorizedWhenInUse){
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
                appDelegate.startLocationKit();
//                locationManager.startUpdatingLocation();
                requestedLocation = true
            }
            if(status == .AuthorizedAlways){
                requestedLocation = true
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
                appDelegate.startLocationKit();
                requestedMotion = true
            }
            updateNextButtonIfNecessary()
    }
    
    @IBAction func motionPermissionButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedMotion) {
            self.requestMotionAccessData();
            requestedMotion = true
        }
    }
    
    @IBAction func pushNotificationsButtonPressed(sender: UISwitch) {
        if (sender.on && !requestedPush) {
            let application = UIApplication.sharedApplication();
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            requestedPush = true
        }
    }
    
    func requestMotionAccessData(){
        let cmManager = CMMotionActivityManager();
        let motionActivityQueue = NSOperationQueue();
        cmManager.startActivityUpdatesToQueue(motionActivityQueue) { (activity:CMMotionActivity?) -> Void in
            cmManager.stopActivityUpdates();
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
            appDelegate.startLocationKit();
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