//
//  SOSignInViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/4/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOSignInViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.usernameTextField.delegate = self;
        self.passwordTextField.delegate = self;
    }
    
    @IBAction func signInButtonPressed(sender: AnyObject) {
        
        PFUser.logInWithUsernameInBackground(usernameTextField.text!, password: passwordTextField.text!) { (user:PFUser?, error:NSError?) -> Void in
            if ((user) != nil){
                self.performSegueWithIdentifier("signInToMap", sender: self);
            }
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
}