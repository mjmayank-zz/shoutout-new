//
//  SOSettingsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/23/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOSettingsViewController : UIViewController{

    override func viewDidLoad(){
        super.viewDidLoad();
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}