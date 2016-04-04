//
//  SOConfirmPhoneNumberViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 4/3/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOConfirmPhoneNumberViewController: UIViewController {
    @IBOutlet var textField: UITextField!
    @IBOutlet var confirmTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        if (textField.text?.characters.count != 10){
            showAlert("Phone Login", message: NSLocalizedString("You must enter a 10-digit US phone number including area code.", comment: "warningPhone"))
            return
        }
        if (textField.text != confirmTextField.text){
            showAlert("Phone Login", message: NSLocalizedString("Phone numbers entered don't match", comment: "warningMatch"))
            return
        }
        PFUser.currentUser()?.setObject(textField.text!, forKey: "phoneNumber")
        PFUser.currentUser()?.saveInBackground()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func noUSPhoneButtonPressed(sender: AnyObject) {
        let alertview = JSSAlertView().show(self, title: "No worries!", text: "International users will still be able to log back in with their existing username and password", buttonText: "Awesome!", color:UIColor(CSS: "2ECEFF"))
        alertview.addAction {
            PFUser.currentUser()?.setObject("international", forKey: "phoneNumber")
            PFUser.currentUser()?.saveInBackground()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertview.setTitleFont("Titillium-Bold")
        alertview.setTextFont("Titillium")
        alertview.setButtonFont("Titillium-Light")
        alertview.setTextTheme(.Light)
    }
    
    func showAlert(title: String, message: String) {
        return UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: NSLocalizedString("OK", comment:"alertOK")).show()
    }
}