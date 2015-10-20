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
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2
        self.profileImageView.clipsToBounds = true
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil);
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard");
        self.view .addGestureRecognizer(tap);
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
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
                let errorString = error.userInfo["error"] as? String
                print(errorString);
                let alert = UIAlertController(title: errorString!, message: "Please try again", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                    // Do nothing
                })
                alert.addAction(defaultAction)
                self.presentViewController(alert, animated: true, completion: { () -> Void in
                    self.usernameTextField.becomeFirstResponder()
                })
                // Show the errorString somewhere and let the user try again.
            } else {
                let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("NUXPermissions")
                // Hooray! Let them use the app now.
                self.navigationController?.setViewControllers([newVC!], animated: true)
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
        self.profileImageView.contentMode = .ScaleToFill;
        self.profileImageView.image = chosenImage;
        
        let parseImageData = UIImageJPEGRepresentation(chosenImage, 0.05);
        let imageFile = PFFile(data: parseImageData!);
        
        imageFile?.saveInBackgroundWithBlock({ (succeeded:Bool, error:NSError?) -> Void in
            if(error == nil){
                let photo = PFObject(className: "Images");
                photo.setObject(imageFile!, forKey: "image");
                
                photo.saveInBackgroundWithBlock({ (succeeded:Bool, error:NSError?) -> Void in
                    if(error == nil){
                        PFUser.currentUser()?.setObject(photo, forKey: "profileImage");
                    }
                })
            }
        });
        
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    func dismissKeyboard(){
        passwordTextField.resignFirstResponder();
        usernameTextField.resignFirstResponder();
        emailTextField.resignFirstResponder();
    }
    
    func keyboardWillShow(notification: NSNotification){
        if(self.view.frame.origin.y == 0.0){
            self.view.frame.offsetInPlace(dx: 0, dy: -100)
        }
    }
    
    func keyboardWillHide(notification: NSNotification){
        if(self.view.frame.origin.y != 0.0){
            self.view.frame.offsetInPlace(dx: 0, dy: 100)
        }
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}