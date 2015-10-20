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
        self.usernameTextField.becomeFirstResponder()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func login() {
        PFUser.logInWithUsernameInBackground(usernameTextField.text!, password: passwordTextField.text!) { (user:PFUser?, error:NSError?) -> Void in
            if ((user) != nil){
                let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("NUXPermissions")
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate;
                appDelegate.startLocationKit();
                self.navigationController?.setViewControllers([newVC!], animated: true)
            }
            
            if ((error) != nil) {
                let alert = UIAlertController(title: "Invalid login", message: "Please try again", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                    // Do nothing
                })
                alert.addAction(defaultAction)
                self.presentViewController(alert, animated: true, completion: { () -> Void in
                    self.usernameTextField.becomeFirstResponder()
                })
            }
        }
    }
    
    @IBAction func signInButtonPressed(sender: AnyObject) {
        login()
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == usernameTextField) {
            textField.resignFirstResponder();
            passwordTextField.becomeFirstResponder()
        } else {
            login()
        }
        return true
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}