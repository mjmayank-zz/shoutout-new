//
//  SOBlockMapViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 11/24/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOBlockMapViewController: UIViewController{
    
    @IBOutlet var instructionLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad();
        var string = self.instructionLabel.text
        string = string?.stringByReplacingOccurrencesOfString("\\n", withString: "\n\n")
        self.instructionLabel.text = string;
    }
    
    override func viewDidAppear(animated:Bool){
        super.viewDidAppear(animated);
        if((PFUser.currentUser()?["visible"].boolValue) == true && CLLocationManager.authorizationStatus() != .Denied){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    @IBAction func enableVisibilityButtonPressed(sender: AnyObject) {
        PFUser.currentUser()?.setObject(NSNumber(bool: true), forKey: "visible")
        PFUser.currentUser()?.saveInBackground()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}