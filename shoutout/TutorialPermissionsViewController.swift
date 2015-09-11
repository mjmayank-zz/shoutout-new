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

class TutorialPermissionsViewController: UIViewController, CLLocationManagerDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate{
    
    @IBOutlet var locationServicesButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var facebookButton: UIButton!
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
    }
    @IBAction func locationPermissionButtonPressed(sender: AnyObject) {
        locationManager.requestWhenInUseAuthorization();
    }
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            if(status == .AuthorizedWhenInUse){
                println("got it");
                locationManager.startUpdatingLocation();
                locationServicesButton.hidden = true;
                facebookButton.enabled = true;
            }
    }
    @IBAction func facebookLoginPressed(sender: AnyObject) {
        self.promptLogin();
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
            logInViewController.fields = PFLogInFields.Facebook | PFLogInFields.DismissButton; //Facebook login, and a Dismiss button.
            
            // Present the log in view controller
            self.presentViewController(logInViewController, animated: true, completion: nil);
        }
        else{
        
        }
    }

    // Sent to the delegate to determine whether the log in request should be submitted to the server.
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        if ((count(username) != 0) && (count(password) != 0)){
            return true;
        }
    
        let alert = UIAlertView(title: "Missing Information", message: "Make sure you fill out all of the information", delegate: nil, cancelButtonTitle: "ok");
        alert.show();
        
        return false; // Interrupt login process
    }
    
    // Sent to the delegate when a PFUser is logged in.
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        print(locationManager);
        
        if let loc = locationManager.location{
            if let user = PFUser.currentUser(){
                user.setObject(PFGeoPoint(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude), forKey: "geo");
                user.saveInBackground();
            }
        }
        nextButton.enabled = true;
        facebookButton.hidden = true;
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        println("Failed to log in...");
        println(error);
    }
    
    // Sent to the delegate when the log in screen is dismissed.
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        if let navigationController = self.navigationController{
            navigationController.popViewControllerAnimated(true);
        }
    }
}