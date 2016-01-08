//
//  AppDelegate.swift
//  iCollector
//
//  Created by Nhan Nguyen on 2/12/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import CoreTelephony

//let mode = "ACCURATE"
let mode = "NEAR-ACCURATE"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    var significantChangeLocationCollector = SignificantChangeLocationCollector()
    var informationSender = InformationSender()
    var activityCollector = ActivityCollector()
    let configuration = Configuration()
     var callCenter = CTCallCenter()
//    var locationCollector = LocationCollector()
    
    func block (call:CTCall!) {
        println(call.callState)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        informationSender.getBatteryStatus()
        Util.getNetWorkInfo()
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            significantChangeLocationCollector.requestPermission()
        }
        
        Util.createSentDirectory()
        
        var myapp = UIApplication.sharedApplication()
        if (myapp.backgroundRefreshStatus == UIBackgroundRefreshStatus.Denied) {
            var alert : UIAlertView = UIAlertView(title: "Alert", message: "You need to turn Background App Refresh on. To do it, go to Settings > General > Background App Refres", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        } else if (myapp.backgroundRefreshStatus == UIBackgroundRefreshStatus.Restricted) {
            var alert : UIAlertView = UIAlertView(title: "Alert", message: "You need to change the restriction of Background App Refresh. To do it, go to Settings > General > Background App Refres", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        } else {
            
            Util.getDeviceInformation()
            informationSender.getBatteryStatus()
            
//            activityCollector.getActivityData({(successActivity) in
//                if (successActivity!) {
//
//                }
//            })
            
            
            if (mode == "ACCURATE") {
//                locationCollector.startLocationCollecting()
//                let time : NSTimeInterval = configuration.timeToSave
//                var locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(time, target: self,
//                selector: "updateLocation", userInfo: nil, repeats: true)
            } else {
                significantChangeLocationCollector.startLocationCollecting()
//                let time : NSTimeInterval = configuration.timeToSave
//                var locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(time, target: self,
//                selector: "significantUpdateLocation", userInfo: nil, repeats: true)
            }

            
//        }
        
        if launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil { //need to be commented if use the ACCURATE mode
            println("It's a location event")
            significantChangeLocationCollector.restartLocationUpdates()
        }

        }
        
        return true
    }
    
    func updateLocation() {
        println("updating location")
//        locationCollector.updateLocationToServer()
    }
    
    func significantUpdateLocation() {
        println("updating location to server")
//        significantChangeLocationCollector.outputList()
        //        locationCollector.updateLocationToServer()
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

