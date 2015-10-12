//
//  SONUXViewController.swift
//  shoutout
//
//  Created by Raj Ramamurthy on 10/7/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import UIKit

class SONUXViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var controllers = [UIViewController]()
    @IBOutlet weak var backgroundView: UIImageView!
    var pageViewController: UIPageViewController!
    
    override func prepareForSegue(segue:(UIStoryboardSegue!), sender:AnyObject!)
    {
        if (segue.identifier == "NUXPageViewControllerSegue")
        {
            pageViewController = segue!.destinationViewController as! UIPageViewController
            self.pageViewController?.dataSource = self
            self.pageViewController?.delegate = self
            
            let pageOne = self.storyboard?.instantiateViewControllerWithIdentifier("onboardingPage1")
            let pageTwo = self.storyboard?.instantiateViewControllerWithIdentifier("onboardingPage2")
            let pageThree = self.storyboard?.instantiateViewControllerWithIdentifier("onboardingPage3")
            let pageFour = self.storyboard?.instantiateViewControllerWithIdentifier("onboardingPage4")
            controllers.append(pageOne!)
            controllers.append(pageTwo!)
            controllers.append(pageThree!)
            controllers.append(pageFour!)
            
            self.pageViewController?.setViewControllers([controllers[0]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
            
            self.pageViewController?.view.frame = CGRectInset(self.view.frame, 50.0, 50.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let idx = controllers.indexOf(viewController) {
            if (idx == 0) {
                return nil
            }
            
            return controllers[idx-1]
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let idx = controllers.indexOf(viewController) {
            if (idx == controllers.count-1) {
                return nil
            }
            
            return controllers[idx+1]
        }
        return nil
    }
    
    // MARK: Page indicator
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return controllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: Status bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
