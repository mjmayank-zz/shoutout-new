//
//  SOSettingsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/23/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOSettingsViewController : UIViewController{

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameTextField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.usernameTextField.text = PFUser.currentUser()?.username
        
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func privacyChanged(sender: AnyObject) {
        let privacySwitch = sender as! UISwitch;
        let privacyStatus = privacySwitch.on ? "YES" : "NO";
        let shoutoutRootPrivacy = Firebase(url: "https://shoutout.firebaseio.com/privacy");
        shoutoutRootPrivacy.childByAppendingPath(PFUser.currentUser()?.objectId).childByAppendingPath("privacy").setValue(privacyStatus);
        PFUser.currentUser()?["visible"] = NSNumber(bool: privacySwitch.on);
        PFUser.currentUser()?.saveInBackground();
        
        if(privacySwitch.on){
            LocationKit.sharedInstance().resume();
        }
        else{
            LocationKit.sharedInstance().pause();
        }
    }
    
    @IBAction func logoutButtonPressed(sender: AnyObject) {
        PFUser.logOut();
        self.performSegueWithIdentifier("logoutToStart", sender: self);
    }
    @IBAction func changeUsernameButtonPressed(sender: AnyObject) {
        PFUser.currentUser()?.username = self.usernameTextField.text;
        PFUser.currentUser()?.saveInBackground();
    }
}