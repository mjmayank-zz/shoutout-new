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
    weak var delegate: ViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createViewControllers()
    }
    
    @IBAction func nextButtonPressed(sender: UIButton) {
        if (contentView.subviews.count > 0) {
            contentView.subviews[0].removeFromSuperview()
        }
        if (currentSlide == 3) {
            let application = UIApplication.sharedApplication();
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            PFAnalytics.trackEvent("allowedPush", dimensions:nil)
            currentSlide = (currentSlide + 1) % contentViewControllers.count
            displayViewController(currentSlide)
        } else if (currentSlide == 5) {
            delegate.completeNUX()
        } else {
            currentSlide = (currentSlide + 1) % contentViewControllers.count
            displayViewController(currentSlide)
        }
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
        case 1:
            popover.pip?.hidden = false
            popover.updatePipLocationAndAnimate(105.0, duration: 0.3)
            nextButton.setTitle("Next", forState: .Normal)
            slideTitle.text = "List View"
        case 2:
            popover.pip?.hidden = false
            popover.updatePipLocationAndAnimate(242.0, duration: 0.3)
            nextButton.setTitle("Next", forState: .Normal)
            slideTitle.text = "Inbox View"
        case 3:
            popover.pip?.hidden = false
            popover.updatePipLocationAndAnimate(170.0, duration: 0.3)
            nextButton.setTitle("Got it!", forState: .Normal)
            slideTitle.text = "Shout! Let it all out!"
        case 4:
            popover.pip?.hidden = false
            popover.updatePipLocationAndAnimate(35.0, duration: 0.3)
            nextButton.setTitle("Next", forState: .Normal)
            slideTitle.text = "Settings"
        case 5:
            popover.pip?.hidden = false
            popover.updatePipLocationAndAnimate(292.0, duration: 0.3)
            nextButton.setTitle("Enable Location Permissions", forState: .Normal)
            slideTitle.text = "Last but not least"
        default:
            return
        }
    }
    
    func showInitialController() {
        displayViewController(0)
    }
    
    func createViewControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let introSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialText") as? SONUXTutorialTextViewController
        introSlide?.view
        introSlide?.textView.text = "Before you can get started, we need to show you a couple of things about the app.\n\nShoutout is all about getting on the map. In order for this to work, we need to get your permissions and show you how everything works."
        contentViewControllers.append(introSlide)
        
        let listSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialTextImage") as? SONUXTutorialTextImageViewController
        listSlide?.view
        listSlide?.textView.text = "Too many people on the map?\n\nTry using List View to help sort through the masses."
        contentViewControllers.append(listSlide)
        // MAYANK-TODO: set to image of list
        
        let inboxSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialTextImage") as? SONUXTutorialTextImageViewController
        inboxSlide?.view
        inboxSlide?.textView.text = "If someone shouts back at you, it will show up here. From here, you can also block the haters and find your homies."
        contentViewControllers.append(inboxSlide)
        // MAYANK-TODO: set to image of inbox
        
        let notificationsSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialTextPermission") as? SONUXTutorialTextPermissionViewController
        notificationsSlide?.view
        notificationsSlide?.textView.text = "This is how you let anyone on the map know what you're up to or thinking about."
        notificationsSlide?.textBelowImageView.text = "We need your permission to let you know when others message you."
        contentViewControllers.append(notificationsSlide)
        // MAYANK-TODO: set to image of shoutout pin
        
        let settingsSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialTextPermission") as? SONUXTutorialTextPermissionViewController
        settingsSlide?.view
        settingsSlide?.textView.text = "This is where you can change your settings and tweak your profile."
        settingsSlide?.textBelowImageView.text = "You can also switch to anonymous mode if you want to be a shade-ball."
        contentViewControllers.append(settingsSlide)
        // MAYANK-TODO: set to image of settings
        
        let locationSlide = storyboard.instantiateViewControllerWithIdentifier("soTutorialText") as? SONUXTutorialTextViewController
        locationSlide?.view
        locationSlide?.textView.text = "Shoutout relies on all users sharing their location. In order to use the app, please enable location permissions."
        contentViewControllers.append(locationSlide)
        // MAYANK-TODO: set to image of settings
        
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
