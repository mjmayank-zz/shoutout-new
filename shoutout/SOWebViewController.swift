//
//  SOWebView.swift
//  shoutout
//
//  Created by Mayank Jain on 10/29/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOWebViewController: UIViewController{
    @IBOutlet var webView: UIWebView!
    var URLString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        let URL = NSURL(string: URLString)
        self.webView.loadRequest(NSURLRequest(URL: URL!))
    }
    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}