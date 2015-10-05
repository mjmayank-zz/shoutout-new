//
//  SOCreateProfileViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/3/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOCreateProfileViewController : UIViewController, UITextFieldDelegate{
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.passwordTextField.delegate = self;
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        let user = PFUser();
        user.username = usernameTextField.text;
        user.email = emailTextField.text;
        user.password = passwordTextField.text;
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError?) -> Void in
            if let error = error {
                let errorString = error.userInfo["error"] as? NSString
                print(errorString);
                // Show the errorString somewhere and let the user try again.
            } else {
                self.performSegueWithIdentifier("createProfileToMap", sender: self);
                // Hooray! Let them use the app now.
            }
        }
    }
    
    @IBAction func addPictureButtonPressed(sender: AnyObject) {
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
}