//
//  SOFeedbackViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/5/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOFeedbackViewController: UIViewController{
    @IBOutlet var feedbackTextView: UITextField!
    override func viewDidLoad(){
        super.viewDidLoad();
        
        PFAnalytics.trackEvent("openedFeedback", dimensions:nil);
    }
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    @IBAction func submitButtonPressed(sender: AnyObject) {
        let feedback = PFObject(className: "Feedback");
        feedback.setObject(PFUser.currentUser()!, forKey: "author");
        feedback.setObject(self.feedbackTextView.text!, forKey: "message");
        feedback.saveInBackground();
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}