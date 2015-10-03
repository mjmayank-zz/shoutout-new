//
//  SOCreateProfileViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/3/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOCreateProfileViewController : UIViewController{
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    override func viewDidLoad(){
        super.viewDidLoad();
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        let user = PFUser();
        user.username = usernameTextField.text;
        user.email = emailTextField.text;
        user.password = passwordTextField.text;
        user.saveInBackground();
    }
    
    @IBAction func addPictureButtonPressed(sender: AnyObject) {
        
    }
}