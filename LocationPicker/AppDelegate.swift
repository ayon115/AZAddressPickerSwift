//
//  AppDelegate.swift
//  LocationPicker
//
//  Created by Ashiq Uz Zoha on 18/12/18.
//  Copyright © 2018 DISL. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "lat") == nil {
            defaults.set(51.504831314, forKey: "lat")
            defaults.synchronize()
        }
        
        if defaults.object(forKey: "lng") == nil {
            defaults.set(-0.085999656, forKey: "lng")
            defaults.synchronize()
        }
        
        IQKeyboardManager.shared.enable = true
        self.fetchLocation()
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if locationManager != nil {
            locationManager.stopUpdatingLocation()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.fetchLocation()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    
    func fetchLocation () {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
        }
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func saveLocation(location: CLLocation) {
        //  print("save location")
        let defaults = UserDefaults.standard
        defaults.set(location.coordinate.latitude, forKey: "lat")
        defaults.set(location.coordinate.longitude, forKey: "lng")
        defaults.synchronize()
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    // MARK: CLLocationManager Delegates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var location : CLLocation!
        if locations.count > 0 {
            location = locations.first
            for loc in locations {
                if loc.horizontalAccuracy < location.horizontalAccuracy {
                    location = loc
                }
            }
        }
        
        if location != nil {
            self.saveLocation(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location request failed with error")
    }
}

