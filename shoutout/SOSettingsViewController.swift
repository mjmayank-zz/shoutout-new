//
//  SOSettingsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/23/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOSettingsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var privacyToggle: UISwitch!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var sendFeedbackButton: UIButton!
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var anonymousToggle: UISwitch!
    
    var oldVC: UIViewController!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        
        PFAnalytics.trackEvent("openedSettings", dimensions:nil);
        
        self.usernameTextField.text = PFUser.currentUser()?.username
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height/2.0;
        self.profileImageView.layer.masksToBounds = true;
        if let on = PFUser.currentUser()?["visible"]{
            self.privacyToggle.on = on.boolValue;
        }
        
        if let anon = PFUser.currentUser()?["anonymous"]{
            self.anonymousToggle.on = anon.boolValue;
        }
        
        self.updateButton.layer.cornerRadius = 5.0;
        self.sendFeedbackButton.layer.cornerRadius = 5.0;
        self.logoutButton.layer.cornerRadius = 5.0;
        
        let profileImageObj = PFUser.currentUser()?["profileImage"];
        if let profileImageObj = profileImageObj{
            profileImageObj.fetchIfNeededInBackgroundWithBlock({ (object:PFObject?, error:NSError?) -> Void in
                if let file = profileImageObj["image"] as? PFFile{
                    file.getDataInBackgroundWithBlock({ (data:NSData?, error:NSError?) -> Void in
                        self.profileImageView.image = UIImage(data: data!);
                    })
                }
            })
        }
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func anonymousChanged(sender: AnyObject) {
        let privacySwitch = sender as! UISwitch;
        PFUser.currentUser()?["anonymous"] = NSNumber(bool: privacySwitch.on);
        PFUser.currentUser()?.saveInBackground();
    }
    
    @IBAction func privacyChanged(sender: AnyObject) {
        let privacySwitch = sender as! UISwitch;
        let privacyStatus = privacySwitch.on ? "YES" : "NO";
        let shoutoutRootPrivacy = Firebase(url: "https://shoutout.firebaseio.com/privacy");
        shoutoutRootPrivacy.childByAppendingPath(PFUser.currentUser()?.objectId).childByAppendingPath("privacy").setValue(privacyStatus);
        PFUser.currentUser()?["visible"] = NSNumber(bool: privacySwitch.on);
        PFUser.currentUser()?.saveInBackground();
        
        if(privacySwitch.on){
            LocationManager.sharedLocationManager().enterForegroundMode();
        }
        else{
            LocationManager.sharedLocationManager().stopLocationUpdates();
        }
    }
    
    @IBAction func logoutButtonPressed(sender: AnyObject) {
        if((PFUser.currentUser()) != nil){
            let shoutoutOnline = Firebase(url: "https://shoutout.firebaseio.com/online");
            shoutoutOnline.childByAppendingPath(PFUser.currentUser()?.objectId).setValue("NO");
            PFUser.currentUser()?.setObject(NSNumber(bool: false), forKey: "online");
            PFUser.currentUser()?.saveInBackground();
        }
        
        PFUser.logOut();
        let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("SONUXVC")
        oldVC.navigationController?.setViewControllers([newVC!], animated: false)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func changeUsernameButtonPressed(sender: AnyObject) {
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
        PFUser.currentUser()?.username = self.usernameTextField.text?.lowercaseString;
        PFUser.currentUser()?.saveInBackground();
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
                        PFUser.currentUser()?.saveInBackground();
                    }
                })
            }
        });
        
        dismissViewControllerAnimated(true, completion: nil);
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil);

    }
    
    override func prepareForSegue(segue:(UIStoryboardSegue!), sender:AnyObject!)
    {
        if(segue.identifier == "settingsToFeedback"){
            let webVC = segue.destinationViewController as! SOWebViewController
            webVC.URLString = "http://www.getshoutout.co/feedback.html"
        }
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