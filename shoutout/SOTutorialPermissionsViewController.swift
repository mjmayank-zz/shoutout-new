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
    
    @IBOutlet var locationServicesButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    let locationManager = CLLocationManager();
    
    override func viewDidLoad(){
        super.viewDidLoad();
        
        if(PFUser.currentUser() != nil){
            PFUser.logOut();
        }
        
        locationManager.delegate = self;
        if(PFUser.currentUser() != nil){
            self.nextButton.enabled = true;
        }
        
        if(CLLocationManager.locationServicesEnabled()){
            self.nextButton.enabled = true;
        }
    }
    @IBAction func locationPermissionButtonPressed(sender: AnyObject) {
        locationManager.requestAlwaysAuthorization();
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            if(status == .AuthorizedWhenInUse){
                print("got it");
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
                appDelegate.startLocationKit();
//                locationManager.startUpdatingLocation();
                locationServicesButton.hidden = true;
            }
            if(status == .AuthorizedAlways){
                locationServicesButton.hidden = true;
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
                appDelegate.startLocationKit();
                nextButton.enabled = true;
            }
    }
    @IBAction func facebookLoginPressed(sender: AnyObject) {
        self.promptLogin();
    }
    
    @IBAction func motionPermissionButtonPressed(sender: AnyObject) {
        self.requestMotionAccessData();
        let button = sender as! UIButton;
        button.hidden = true;
    }
    
    @IBAction func pushNotificationsButtonPressed(sender: AnyObject) {
        let application = UIApplication.sharedApplication();
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        let button = sender as! UIButton;
        button.hidden = true;
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
    
    
    func promptLogin(){
        if (PFUser.currentUser() == nil) { // No user logged in
            // Create the log in view controller
            let logInViewController = PFLogInViewController();
            logInViewController.delegate = self; // Set ourselves as the delegate
            
            // Create the sign up view controller
            let signUpViewController = PFSignUpViewController();
            signUpViewController.delegate = self; // Set ourselves as the delegate
            
            // Assign our sign up controller to be displayed from the login controller
            logInViewController.signUpController = signUpViewController;
            
            logInViewController.facebookPermissions = ["email"];
            logInViewController.fields = [PFLogInFields.Facebook, PFLogInFields.DismissButton]; //Facebook login, and a Dismiss button.
            logInViewController.logInView?.logo = UIImageView(image: UIImage(named: "shoutout_green"));
            
            // Present the log in view controller
            self.presentViewController(logInViewController, animated: true, completion: nil);
        }
        else{
        
        }
    }

    // Sent to the delegate to determine whether the log in request should be submitted to the server.
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        if ((username.characters.count != 0) && (password.characters.count != 0)){
            return true;
        }
    
        let alert = UIAlertView(title: "Missing Information", message: "Make sure you fill out all of the information", delegate: nil, cancelButtonTitle: "ok");
        alert.show();
        
        return false; // Interrupt login process
    }
    
    // Sent to the delegate when a PFUser is logged in.
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        print(locationManager, terminator: "");
        
        if let loc = locationManager.location{
            if let user = PFUser.currentUser(){
                user.setObject(PFGeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude), forKey: "geo");
                user.saveInBackground();
                locationManager.stopUpdatingLocation();
            }
        }
        nextButton.enabled = true;
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        print("Failed to log in...");
        print(error);
    }
    
    // Sent to the delegate when the log in screen is dismissed.
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        if let navigationController = self.navigationController{
            navigationController.popViewControllerAnimated(true);
        }
    }
}