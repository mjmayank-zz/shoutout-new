//
//  SOBlockMapViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 11/24/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOBlockMapViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewDidAppear(animated:Bool){
        super.viewDidAppear(animated);
        if((PFUser.currentUser()?["visible"].boolValue) == true){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}