//
//  InventoryItemPageViewController.swift
//  OnTrack
//
//  Created by Peter Hitchcock on 12/5/17.
//  Copyright © 2017 Peter Hitchcock. All rights reserved.
//

import UIKit

class InventoryItemPageViewController: UIPageViewController {
    
    var inventoryItem: Inventory!
    var arr: [String]!
    var str: String!
    var orderedViewControllers = [UIViewController]()
    /*
    let orderedViewControllers: [UIViewController] = {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        var viewControllers = [UIViewController]()
        
        
        let viewController = storyboard.instantiateViewController(withIdentifier: "InventoryStatsViewController") as! InventoryStatsViewController
        //viewController.index = 0
        //viewController.inventoryItem = inventoryItem
        viewControllers.append(viewController)
        
        let viewController1 = storyboard.instantiateViewController(withIdentifier: "InventoryImagesViewController") as! InventoryImagesViewController
        //viewController.index = 1
        //viewController1.inventoryItem = inventoryItem
        viewControllers.append(viewController1)
        
        //InventoryItemMapViewController
        let viewController2 = storyboard.instantiateViewController(withIdentifier: "InventoryItemMapViewController") as! InventoryItemMapViewController
        //viewController.index = 1
        //viewController2.inventoryItem = inventoryItem
        viewControllers.append(viewController2)
        
        return viewControllers
    }()
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        self.delegate = self
        let storyboard = UIStoryboard(name: "Inventory", bundle: Bundle.main)
        
        let viewController2 = storyboard.instantiateViewController(withIdentifier: "InventoryItemMapViewController") as! InventoryItemMapViewController
        viewController2.inventoryItem = inventoryItem
        orderedViewControllers.append(viewController2)
        
        let viewController1 = storyboard.instantiateViewController(withIdentifier: "InventoryImagesViewController") as! InventoryImagesViewController
        viewController1.inventoryItem = inventoryItem
        orderedViewControllers.append(viewController1)
        
        //InventoryItemMapViewController
        
        let viewController = storyboard.instantiateViewController(withIdentifier: "InventoryStatsViewController") as! InventoryStatsViewController
        viewController.inventoryItem = inventoryItem
        orderedViewControllers.append(viewController)
        
        let viewController3 = storyboard.instantiateViewController(withIdentifier: "InventoryDetailsViewController") as! InventoryDetailsViewController
        viewController3.inventoryItem = inventoryItem
        orderedViewControllers.append(viewController3)
        
        if let firstVC = orderedViewControllers.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: { (action) in
                
            })
        }
    }
}

extension InventoryItemPageViewController: UIPageViewControllerDataSource {
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

extension InventoryItemPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    }
}
