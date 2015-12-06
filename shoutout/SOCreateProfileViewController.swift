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
    var chosenImageObj : PFObject?
    var termsChecked = false;
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.width / 2
        self.profileImageView.clipsToBounds = true
        self.passwordTextField.delegate = self;
        self.usernameTextField.delegate = self;
        self.emailTextField.delegate = self;
        
        self.loadRandomDefaultImage();
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil);
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissKeyboard");
        self.view .addGestureRecognizer(tap);
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func loadRandomDefaultImage(){
        PFQuery(className: "DefaultImage").getFirstObjectInBackgroundWithBlock { (object:PFObject?, error:NSError?) -> Void in
            if let object = object{
                let array = object.objectForKey("images") as! [AnyObject];
                let random = Int(arc4random_uniform(UInt32(array.count)));
                array[random].fetchIfNeededInBackgroundWithBlock({ (pic:PFObject?, error:NSError?) -> Void in
                    if let pic = pic{
                        self.chosenImageObj = pic;
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
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        let validUsername = self.validateUsername(usernameTextField.text!)
        if(!validUsername){
            let alert = UIAlertController(title: "Invalid username", message: "Your username can only consist of letters, numbers and underscores", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                // Do nothing
            })
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if(!termsChecked){
            let alert = UIAlertController(title: "You must agree to the terms of service!", message: "Please read them and check the box", preferredStyle: .Alert)
            let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
                // Do nothing
            })
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let user = PFUser();
        user.username = usernameTextField.text?.lowercaseString;
        user.email = emailTextField.text?.lowercaseString;
        user.password = passwordTextField.text;
        user["displayName"] = usernameTextField.text!
        user["profileImage"] = self.chosenImageObj;
        user["status"] = "";
        user["visible"] = NSNumber(bool: true);
        user["platform"] = "iOS"
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
        let alertController = UIAlertController(title: "Set your profile picture", message: "Choose a method", preferredStyle: .ActionSheet)
        
        let uploadAction = UIAlertAction(title: "Upload a picture", style: .Default) { (action:UIAlertAction) -> Void in
                    let imagePicker = UIImagePickerController();
                    imagePicker.delegate = self;
                    imagePicker.allowsEditing = true;
                    self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        let randomAction = UIAlertAction(title: "New Random", style: .Default) { (action:UIAlertAction) -> Void in
            self.loadRandomDefaultImage()
        }

        let threeAction = UIAlertAction(title: "Take a picture", style: .Default) { (_) in }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addAction(randomAction)
        alertController.addAction(uploadAction)
        alertController.addAction(threeAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: Delegates
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage;
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
                        self.chosenImageObj = photo;
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
    
    @IBAction func checkboxButtonPressed(sender: AnyObject) {
        self.dismissKeyboard();
        let button = sender as! UIButton as UIButton!
        if(termsChecked){
            button.setImage(UIImage(named: "unchecked_checkbox.png"), forState: UIControlState.Normal)
            termsChecked = false;
        }
        else{
            button.setImage(UIImage(named: "checked_checkbox.png"), forState: UIControlState.Normal)
            termsChecked = true;
        }
    }
    func keyboardWillHide(notification: NSNotification){
        if(self.view.frame.origin.y != 0.0){
            self.view.frame.offsetInPlace(dx: 0, dy: 100)
        }
    }
    
    override func prepareForSegue(segue:(UIStoryboardSegue!), sender:AnyObject!)
    {
        if(segue.identifier == "privacyPolicy"){
            let webVC = segue.destinationViewController as! SOWebViewController
            webVC.URLString = "http://www.getshoutout.co/privacy.html"
        }
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func validateUsername(username:String) -> Bool{
        let set = NSMutableCharacterSet(charactersInString: "_");
        set.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet());
        let finalSet = set.invertedSet;
        
        let range = username.rangeOfCharacterFromSet(finalSet)
        if (range != nil) {
            print("invalid character found")
            return false
        }
        return true;
    }
    
}