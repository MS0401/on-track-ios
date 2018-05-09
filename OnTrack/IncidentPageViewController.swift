//
//  IncidentPageViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/14/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class IncidentPageViewController: UIPageViewController {
    
    var incident: Incident!
    var orderedViewControllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
        
        let viewController = storyboard.instantiateViewController(withIdentifier: "IncidentMapViewController") as! IncidentMapViewController
        viewController.incident = incident
        orderedViewControllers.append(viewController)
        
        let viewController1 = storyboard.instantiateViewController(withIdentifier: "IncidentImageViewController") as! IncidentImageViewController
        viewController1.incident = incident
        orderedViewControllers.append(viewController1)
        
        if let firstVC = orderedViewControllers.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: { (action) in
                
            })
        }
    }
}

extension IncidentPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return orderedViewControllers.first
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first, let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
            return 0
        }
        
        return firstViewControllerIndex
    }
}

extension IncidentPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    }
}

