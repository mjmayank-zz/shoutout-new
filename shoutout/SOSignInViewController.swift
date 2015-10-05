//
//  SOSignInViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/4/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOSignInViewController: UIViewController{
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad();
    }
    
    @IBAction func signInButtonPressed(sender: AnyObject) {
        
        PFUser.logInWithUsernameInBackground(usernameTextField.text!, password: passwordTextField.text!) { (user:PFUser?, error:NSError?) -> Void in
            self.performSegueWithIdentifier("signInToMap", sender: self);
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}