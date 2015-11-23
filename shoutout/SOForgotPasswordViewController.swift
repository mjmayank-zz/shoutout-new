//
//  SOForgotPasswordViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/29/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOForgotPasswordViewController: UIViewController{
    
    @IBOutlet var usernameTextField: UITextField!
    override func viewDidLoad() {
        self.usernameTextField.becomeFirstResponder()
    }
    
    @IBAction func recoverButtonPressed(sender: AnyObject) {
        PFUser.requestPasswordResetForEmailInBackground(usernameTextField.text!.lowercaseString) { (bool:Bool, error:NSError?) -> Void in
            if(error != nil){
                let errorString = error!.userInfo["error"] as? String
                let alert = UIAlertController(title: "Error", message: errorString!, preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                    // Do nothing
                })
                alert.addAction(defaultAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else{
                let alert = UIAlertController(title: "Sent!", message: "Check your email for a password reset message", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                    // Do nothing
                })
                alert.addAction(defaultAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true);
    }
}