//
//  SOCreateProfileViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/3/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOCreateProfileViewController : UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var profileImageView: UIImageView!
    var chosenImage : PFObject?
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.passwordTextField.delegate = self;
        self.usernameTextField.delegate = self;
        self.emailTextField.delegate = self;
        PFQuery(className: "DefaultImage").getFirstObjectInBackgroundWithBlock { (object:PFObject?, error:NSError?) -> Void in
            if let object = object{
                let array = object.objectForKey("images") as! [AnyObject];
                let random = Int(arc4random_uniform(UInt32(array.count)));
                array[random].fetchIfNeededInBackgroundWithBlock({ (pic:PFObject?, error:NSError?) -> Void in
                    if let pic = pic{
                        self.chosenImage = pic;
                        let userImageFile = pic["image"] as! PFFile;
                        userImageFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error:NSError?) -> Void in
                            if !(error != nil) {
                                if let imageData = imageData{
                                    let image = UIImage(data:imageData)
                                    self.profileImageView.image = image;
                                }
                            }
                        })
                    }
                })
            }
        };
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        let user = PFUser();
        user.username = usernameTextField.text;
        user.email = emailTextField.text;
        user.password = passwordTextField.text;
        user["profileImage"] = self.chosenImage;
        user["status"] = "";
        user["visible"] = NSNumber(bool: true);
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
        let imagePicker = UIImagePickerController();
        imagePicker.delegate = self;
        imagePicker.allowsEditing = false
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: Delegates
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage;
        self.profileImageView.contentMode = .ScaleAspectFill;
        self.profileImageView.image = chosenImage;
        dismissViewControllerAnimated(true, completion: nil);
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
}