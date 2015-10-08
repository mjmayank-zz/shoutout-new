//
//  SONUXViewController.swift
//  shoutout
//
//  Created by Raj Ramamurthy on 10/7/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import UIKit

class SONUXViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pageViewController: UIPageViewController?
    var controllers = [UIViewController]()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pageViewController?.dataSource = self
        self.pageViewController?.delegate = self
        
        for i in 0...5 {
            let vc = UIViewController()
            let toAdd = UIView(frame: self.view.frame)
            if i % 2 == 0 {
                toAdd.backgroundColor = UIColor.redColor()
            } else {
                toAdd.backgroundColor = UIColor.blueColor()
            }
            vc.view = toAdd
            controllers.append(vc)
        }
        
        self.pageViewController?.setViewControllers([controllers[0]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        
        self.pageViewController?.view.frame = self.view.frame
        self.addChildViewController(pageViewController!)
        self.view.addSubview((pageViewController?.view)!)
        self.pageViewController?.didMoveToParentViewController(self)
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let idx = controllers.indexOf(viewController) {
            if (idx == 0) {
                return controllers.last
            }
            
            return controllers[idx-1]
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let idx = controllers.indexOf(viewController) {
            if (idx == controllers.count-1) {
                return controllers.first
            }
            
            return controllers[idx+1]
        }
        return nil
    }

}
