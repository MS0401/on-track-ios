//
//  PageViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 10/17/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController {
    
    var arr: [String]!
    var fuelTypes: [Fuel]!
    var orderedViewControllers = [UIViewController]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("fuel types from PageView: \(fuelTypes)")
        
        let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
        
        for i in 0 ..< 2 {
            let viewController = storyboard.instantiateViewController(withIdentifier: "AllFuelViewController") as! AllFuelViewController
            viewController.index = i
            //viewController.fuelTypes = fuelTypes
            orderedViewControllers.append(viewController)
        }

        self.dataSource = self
        self.delegate = self
        
        if let firstVC = orderedViewControllers.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: { (action) in
                
            })
        }
    }
}

extension PageViewController: UIPageViewControllerDataSource {
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

extension PageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    }
}
