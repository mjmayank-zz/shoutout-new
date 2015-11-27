//
//  SOPopoverViewController.swift
//  shoutout
//
//  Created by Raj Ramamurthy on 11/26/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

let POPOVER_CORNER_RADIUS:CGFloat = 20

class SOPopoverViewController:UIViewController {

    @IBOutlet weak var popoverTitle: UILabel?
    @IBOutlet weak var popoverContent: UIView?
    @IBOutlet weak var pip: UIImageView?
    weak var childController: UIViewController?
    var pipLocation: CGFloat?
    
    @IBOutlet private weak var pipConstraint: NSLayoutConstraint?
    @IBOutlet private weak var containerView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popoverContent?.layer.cornerRadius = POPOVER_CORNER_RADIUS
        popoverContent?.layer.masksToBounds = true
    }
    
    func updatePipLocation(location: CGFloat) {
        pipLocation = location
        pipConstraint!.constant = pipLocation! - 20
        view.setNeedsDisplay()
    }
    
    func updateChildController(controller: UIViewController) {
        containerView?.addSubview(controller.view)
        controller.didMoveToParentViewController(self)
        addChildViewController(controller)
        childController = controller
        
        // Add constraints so the child view is the same as the container
        var constraints = [NSLayoutConstraint]()
        let views = [
            "c": controller.view
        ]
        
        // Disable automatic constraint creation so we can precisely position the child view
        containerView?.translatesAutoresizingMaskIntoConstraints = false
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|[c]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: views))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|[c]|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: views))
        NSLayoutConstraint.activateConstraints(constraints)
    }
    
}