//
//  AppDelegate.swift
//  DoughChallenge
//
//  Created by Jared Wheeler on 4/1/17.
//  Copyright © 2017 Jared Wheeler. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //If this is a first-launch, migrate the listing csv into
        //the CoreData stack.  Otherwise, update the local listing
        //data with a fresh pull of the remote listing endpoint.
        if !UserDefaults.standard.bool(forKey: "firstLaunchComplete") {
            DataModel.sharedInstance.initListingData()
            UserDefaults.standard.set(true, forKey: "firstLaunchComplete")
            UserDefaults.standard.synchronize()
        } else {
            DataModel.sharedInstance.updateListingData()
        }
        
        //Boilerplate SplitView stuff
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DataModel.sharedInstance.saveContext()
    }

    // MARK: - Split view
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
           return true
        }
        return false
    }
}
