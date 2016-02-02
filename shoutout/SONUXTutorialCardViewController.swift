//
//  SONUXTutorialCardViewController.swift
//  shoutout
//
//  Created by Raj Ramamurthy on 1/25/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SONUXTutorialCardViewController: UIViewController {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var slideTitle: UILabel!
    @IBOutlet var nextButton: UIButton!
    
    var currentSlide = 0
    var contentViewControllers: [UIViewController!]
    weak var popover: SOPopoverViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewControllers()
    }
    
    @IBAction func nextButtonPressed(sender: UIButton) {
        if (contentView.subviews.count > 0) {
            contentView.subviews[0].removeFromSuperview()
        }
        displayViewController(currentSlide)
    }
    
    func displayViewController(index: Int) {
        contentView.addSubview(contentViewControllers[index].view)
        let contentViewController = contentViewControllers[index]
        var constraints: [NSLayoutConstraint] = []
        let attributes = [NSLayoutAttribute.Width, NSLayoutAttribute.Height, NSLayoutAttribute.CenterX, NSLayoutAttribute.CenterY]
        for attr in attributes {
            constraints.append(NSLayoutConstraint(item: contentViewController.view, attribute: attr, relatedBy: .Equal, toItem: contentView, attribute: attr, multiplier: 1.0, constant: 0))
        }
        NSLayoutConstraint.activateConstraints(constraints)
        
        switch index {
        case 0:
            popover.pip?.hidden = true
            nextButton.setTitle("OK! Let's get on with it", forState: .Normal)
            slideTitle.text = "Welcome to Shoutout"
        default:
            return
        }
    }
    
    func showInitialController() {
        displayViewController(0)
    }
    
    func createViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tutText = storyboard.instantiateViewControllerWithIdentifier("soTutorialText") as? SONUXTutorialTextViewController
        tutText?.view
        tutText?.textView.text = "Before you can get started, we need to show you a couple of things about the app.\n\nShoutout is all about getting on the map. In order for this to work, we need to get your permissions and show you how everything works."
        contentViewControllers.append(tutText)
        
        for contentViewController in contentViewControllers {
            addChildViewController(contentViewController)
            contentViewController.didMoveToParentViewController(self)
            contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        contentViewControllers = []
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        contentViewControllers = []
        super.init(coder: aDecoder)
    }

}
