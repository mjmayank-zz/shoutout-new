//
//  SOSettingsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/23/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class SOSettingsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate{

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var privacyToggle: UISwitch!
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var sendFeedbackButton: UIButton!
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var anonymousToggle: UISwitch!
    @IBOutlet var genderControl: UISegmentedControl!
    @IBOutlet var statusControl: UISegmentedControl!
    @IBOutlet var statusExplanationLabel: UILabel!
    @IBOutlet var colorPickerCollectionView: UICollectionView!
    
    var oldVC: UIViewController!
    let colorPickerDelegate = SOSettingsColorPickerDelegate()
    
    override func viewDidLoad(){
        super.viewDidLoad();
        
        PFAnalytics.trackEvent("openedSettings", dimensions:nil);
        
        self.colorPickerCollectionView.dataSource = self.colorPickerDelegate
        self.colorPickerCollectionView.delegate = self.colorPickerDelegate
        self.colorPickerDelegate.delegate = self;
        
        for i in 0...self.colorPickerDelegate.colors.count-1{
            if let color = PFUser.currentUser()?.objectForKey("pinColor") as? String{
                if(color == self.colorPickerDelegate.colors[i]){
                    self.colorPickerCollectionView.selectItemAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: false, scrollPosition: .None)
                }
            }
            else{
                PFUser.currentUser()?.setObject("2ECEFF", forKey: "pinColor")
                PFUser.currentUser()?.saveInBackground()
            }
        }
        
        self.usernameTextField.text = PFUser.currentUser()?.username
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height/2.0;
        self.profileImageView.layer.masksToBounds = true;
        if ((PFUser.currentUser()?["visible"]) as? Bool == false){
            self.statusControl.selectedSegmentIndex = 0;
            self.statusExplanationLabel.text = "You are off the map, and we won't update your location in the background"
        }
        else if(PFUser.currentUser()?["anonymous"] as? Bool == true){
            self.statusControl.selectedSegmentIndex = 1;
            self.statusExplanationLabel.text = "We removed your username from your pin"
        }
        else{
            PFUser.currentUser()?.setObject(NSNumber(bool: false), forKey: "anonymous")
            PFUser.currentUser()?.saveInBackground()
            self.statusControl.selectedSegmentIndex = 2;
            self.statusExplanationLabel.text = "Awesome, you're good to go!"
        }
        
        if let gender = PFUser.currentUser()?["gender"] as? Int{
            if(gender < 2){
                self.genderControl.selectedSegmentIndex = gender;
            }
            else{
                self.genderControl.selectedSegmentIndex = 2;
            }
        }
        
        self.updateButton.layer.cornerRadius = 5.0;
        self.sendFeedbackButton.layer.cornerRadius = 5.0;
        self.logoutButton.layer.cornerRadius = 5.0;
        
        let profileImageObj = PFUser.currentUser()?["profileImage"];
        if let profileImageObj = profileImageObj{
            profileImageObj.fetchIfNeededInBackgroundWithBlock({ (object:PFObject?, error:NSError?) -> Void in
                if let file = profileImageObj.objectForKey("image") as? PFFile{
                    file.getDataInBackgroundWithBlock({ (data:NSData?, error:NSError?) -> Void in
                        self.profileImageView.image = UIImage(data: data!);
                    })
                }
            })
        }
    }
    
    func loadRandomDefaultImage(){
        PFQuery(className: "DefaultImage").getFirstObjectInBackgroundWithBlock { (object:PFObject?, error:NSError?) -> Void in
            if let object = object{
                let array = object.objectForKey("images") as! [AnyObject];
                let random = Int(arc4random_uniform(UInt32(array.count)));
                array[random].fetchIfNeededInBackgroundWithBlock({ (pic:PFObject?, error:NSError?) -> Void in
                    if let pic = pic{
                        let userImageFile = pic["image"] as! PFFile;
                        userImageFile.getDataInBackgroundWithBlock({ (imageData: NSData?, error:NSError?) -> Void in
                            if !(error != nil) {
                                if let imageData = imageData{
                                    let image = UIImage(data:imageData)
                                    self.profileImageView.image = image;
                                    PFUser.currentUser()?.setObject(pic, forKey: "profileImage");
                                    PFUser.currentUser()?.saveInBackground();
                                }
                            }
                        })
                    }
                })
            }
        };
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func genderChanged(sender: AnyObject) {
        let genderControl = sender as! UISegmentedControl;
        PFUser.currentUser()?["gender"] = genderControl.selectedSegmentIndex;
        PFUser.currentUser()?.saveInBackground();
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
            PFUser.currentUser()?.saveInBackgroundWithBlock({ (bool:Bool, error:NSError?) -> Void in
                PFUser.logOut();
                let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("SONUXVC")
                self.oldVC.navigationController?.setViewControllers([newVC!], animated: false)
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        }
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
        self.usernameTextField.resignFirstResponder();
    }
    
    @IBAction func inviteFriendButtonPressed(sender: AnyObject){
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("inviteFriendsVC")
        self.presentViewController(controller!, animated: true, completion: nil)
    }
    
    @IBAction func statusValueChanged(sender: AnyObject) {
        let statusControl = sender as! UISegmentedControl
        if(statusControl.selectedSegmentIndex == 0){
            let privacyStatus = "NO";
            let shoutoutRootPrivacy = Firebase(url: "https://shoutout.firebaseio.com/privacy");
            shoutoutRootPrivacy.childByAppendingPath(PFUser.currentUser()?.objectId).childByAppendingPath("privacy").setValue(privacyStatus);
            PFUser.currentUser()?["visible"] = NSNumber(bool: false);
            LocationManager.sharedLocationManager().stopLocationUpdates();
            self.statusExplanationLabel.text = "You are off the map, and we won't update your location in the background"
        }
        else if(statusControl.selectedSegmentIndex == 1){
            PFUser.currentUser()?["anonymous"] = NSNumber(bool: true);
            PFUser.currentUser()?["visible"] = NSNumber(bool: true);
            let privacyStatus = "YES";
            let shoutoutRootPrivacy = Firebase(url: "https://shoutout.firebaseio.com/privacy");
            shoutoutRootPrivacy.childByAppendingPath(PFUser.currentUser()?.objectId).childByAppendingPath("privacy").setValue(privacyStatus);
            LocationManager.sharedLocationManager().enterForegroundMode();
            self.statusExplanationLabel.text = "We removed your username from your pin"
        }
        else{
            PFUser.currentUser()?["anonymous"] = NSNumber(bool: false);
            PFUser.currentUser()?["visible"] = NSNumber(bool: true);
            let privacyStatus = "YES";
            let shoutoutRootPrivacy = Firebase(url: "https://shoutout.firebaseio.com/privacy");
            shoutoutRootPrivacy.childByAppendingPath(PFUser.currentUser()?.objectId).childByAppendingPath("privacy").setValue(privacyStatus);
            LocationManager.sharedLocationManager().enterForegroundMode();
            self.statusExplanationLabel.text = "Awesome, you're good to go!"
        }
        PFUser.currentUser()?.saveInBackground();
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResultCancelled.rawValue:
            print("Message was cancelled")
            self.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultFailed.rawValue:
            print("Message failed")
            self.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent.rawValue:
            print("Message was sent")
            self.dismissViewControllerAnimated(true, completion: nil)
        default:
            break;
        }
    }
    
    @IBAction func addPictureButtonPressed(sender: AnyObject) {
        let alertController = UIAlertController(title: "Change your profile picture", message: "Choose a method", preferredStyle: .ActionSheet)
        
        let uploadAction = UIAlertAction(title: "Upload a picture", style: .Default) { (action:UIAlertAction) -> Void in
            let imagePicker = UIImagePickerController();
            imagePicker.delegate = self;
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        let randomAction = UIAlertAction(title: "New Random", style: .Default) { (action:UIAlertAction) -> Void in
            self.loadRandomDefaultImage()
        }
        
        let takeAction = UIAlertAction(title: "Take a picture", style: .Default) { (action:UIAlertAction) -> Void in
            let imagePicker = UIImagePickerController();
            imagePicker.sourceType = .Camera;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = true;
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addAction(randomAction)
        alertController.addAction(uploadAction)
        alertController.addAction(takeAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: Delegates
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        let chosenImage = info[UIImagePickerControllerEditedImage] as! UIImage;
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
    
    func displayPrompt(){
        let alertview = JSSAlertView().show(self, title: "These are locked!", text: "Invite some friends to use Shoutout to unlock these features.", buttonText: "Let's do it", color:UIColor(CSS: "2ECEFF"), cancelButtonText: "Nahhh")
        alertview.addAction {
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("inviteFriendsVC")
            self.presentViewController(controller!, animated: true, completion: nil)
        }
        alertview.setTitleFont("Titillium-Bold")
        alertview.setTextFont("Titillium")
        alertview.setButtonFont("Titillium-Light")
        alertview.setTextTheme(.Light)
    }
    
}

class SOSettingsColorPickerDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDataSource{
    
    weak var delegate: SOSettingsViewController!
    let colors = ["2ECEFF", "29B4B9", "00E4C9", "4CD78B", "A6A8AB", "299AE6"]
    
    override init() {
        super.init()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pinColorCell",forIndexPath:indexPath) as! SOSettingsColorCell
        let image = UIImage(named: "pinWithShadowGrayscale.png", withColor: UIColor(CSS: colors[indexPath.row]))
        cell.imageView.image = image;
        cell.selectedOutlineImageView.hidden = true;
        let whitePin = UIImage(named: "pinWithShadowGrayscale.png", withColor: UIColor.whiteColor())
        cell.selectedOutlineImageView.image = whitePin;
        if(cell.selected){
            cell.selectedOutlineImageView.hidden = false;
        }
        if(indexPath.row == 0){
            cell.lockImageView.hidden = true;
        }
        if(PFUser.currentUser()?.objectForKey("score")?.integerValue > 100){
            cell.lockImageView.hidden = true;
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView,
                          shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool{
        if(PFUser.currentUser()?.objectForKey("score")?.integerValue > 100 && indexPath.row > 0){
            return true;
        }
        else{
            self.delegate.displayPrompt()
            return false;
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        PFUser.currentUser()?.setObject(colors[indexPath.row], forKey: "pinColor")
        PFUser.currentUser()?.saveInBackground()
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SOSettingsColorCell
        cell.selectedOutlineImageView.hidden = false;
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SOSettingsColorCell
        cell.selectedOutlineImageView.hidden = true;
    }
}

class SOSettingsColorCell: UICollectionViewCell{
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedOutlineImageView: UIImageView!
    @IBOutlet var lockImageView: UIImageView!
}