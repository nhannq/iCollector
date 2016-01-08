//
//  SignificantChangeLocationCollector.swift
//  iCollector
//
//  Created by Nhan Nguyen on 2/26/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//


import Foundation
import UIKit
import CoreLocation

let dataType = "slc_location" //significant location change

class SignificantChangeLocationCollector: NSObject, CLLocationManagerDelegate {
    
    var myLastLocation : CLLocationCoordinate2D?
    var myLastLocationAccuracy : CLLocationAccuracy?
    
    var myLocation : CLLocationCoordinate2D?
    var myLocationAccuracy : CLLocationAccuracy?
    
    var locationManager : CLLocationManager
    
    var configuration = Configuration()
    
    var collectorInformation = CollectorInformation()
    
    var startTime = NSDate()
    
    var myLocationArray : NSMutableArray?
    var dateFormatter = NSDateFormatter()
    
    var count = 0
    
    var countSavedLocation = 0
    
    override init() {
        locationManager = CLLocationManager()
        myLocationArray = NSMutableArray()
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = configuration.desiredAccuracy //kCLLocationAccuracyBestForNavigation //take lot of power, phone should be plugged into power source
        //https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CoreLocationConstantsRef/index.html#//apple_ref/c/data/kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = configuration.distanceFilter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    func requestPermission() {
//        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestAlwaysAuthorization()
//        }
    }
    func toJSON(location : CLLocation) -> JSON {
        let timestamp = dateFormatter.stringFromDate(location.timestamp)
        let netWorkInfo = Util.getNetWorkInfo()
        var bSSID = ""
        if (netWorkInfo.count > 0) {
//            println("Network name \(netWorkInfo[0])")
//            println("AP Mac Address  \(netWorkInfo[1])")
            bSSID = netWorkInfo[1]
        }

        
        var json:JSON = [
            "userid" : collectorInformation.userid,
            "deviceid" : collectorInformation.deviceid,
            "dataType" : dataType,
            "local_time" : timestamp,
//            "time" : location.timestamp.description,
//            "startTime" : dateFormatter.stringFromDate(startTime),
//            "latitude" : location.coordinate.latitude,
//            "longtitude" : location.coordinate.longitude,
            "latitude" :  String(format: "%.10f", location.coordinate.latitude),
            "longtitude" : String(format: "%.10f", location.coordinate.longitude),
            "bssid" : bSSID
        ]
        
        return json
    }
    
    func toJSON() -> JSON {
        var scannedResults: [[String : AnyObject]] = []
        var myBestLocation = NSMutableDictionary()
        for(var i=0 ; i < self.myLocationArray!.count; i++){
            var location = self.myLocationArray!.objectAtIndex(i) as! NSMutableDictionary
            var newDict = ["latitude: " : location.objectForKey(LATITUDE) as! CLLocationDegrees,
                            "longitude: " : location.objectForKey(LONGITUDE) as! CLLocationDegrees,
                            "sampledTime" : dateFormatter.stringFromDate(location.objectForKey("time") as! NSDate) as NSObject]
//            var newDict = ["latitude: " : String(format: "%.3f", location.objectForKey(LATITUDE) as! CLLocationDegrees),
//                "longitude: " : String(format: "%.3f", location.objectForKey(LONGITUDE) as! CLLocationDegrees),
//                "sampledTime" : dateFormatter.stringFromDate(location.objectForKey("time") as! NSDate) as NSObject]
            scannedResults.append(newDict)
        }
        self.myLocationArray!.removeAllObjects()
        self.myLocationArray = nil
        self.myLocationArray = NSMutableArray()
        
        let startTimeString = dateFormatter.stringFromDate(startTime)
        
        //Scanned results needs an array of dictionaries.
        var json:JSON = [
            "userid" : collectorInformation.userid,
            "deviceid" : collectorInformation.deviceid,
            "dataType" : dataType,
            "startTime" : startTimeString,
            "scannedResults" : scannedResults
        ]
        
        return json
    }
    
    func output(location : CLLocation) {
        var result = toJSON(location).description + "\n"
        println(result)
        var subdirectoryName = Util.getDataDirectoryName()
        var fileName = "location.txt" //Util.getDataFileName() +
        Util.saveData(result, path:fileName, subdirectory:subdirectoryName)
//        println("Save data to file \(fileName) of directory \(subdirectoryName)")
    }
    
    func outputList() {
        var result = toJSON().description
        var subdirectoryName = Util.getDataDirectoryName()
        var fileName = Util.getDataFileName() + "-location.json"
        Util.saveData(result, path:fileName, subdirectory:subdirectoryName)
//        println("Read from file \(fileName) of directory \(subdirectoryName)")
        
        countSavedLocation++
        
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("\ngetting significant Location \(count++)") //" : \(locations.count)")
        
        var realLocations: [CLLocation] = locations as! [CLLocation]
        var newLocation : CLLocation = realLocations[locations.count-1]
        var theLocation = newLocation.coordinate //CLLocationCoordinate2D
        var dict = NSMutableDictionary() // NSMutableDictionary alloc]init];
        dict.setObject(theLocation.latitude as CLLocationDegrees, forKey: "latitude")
        var temp = theLocation.latitude // stringWithFormat:@"%f", theLocation.latitude];
//        println("\(temp)")
        dict.setObject(theLocation.longitude as CLLocationDegrees, forKey: "longitude")
        temp = theLocation.longitude
//        println("\(temp)")
        dict.setObject(newLocation.timestamp, forKey: "time")
        myLocationArray?.addObject(dict)

        
        output(newLocation)
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        switch (error.code)
        {
        case CLError.Network.rawValue: // general, network-related error
            var alert : UIAlertView = UIAlertView(title: "Network Error", message: "Please check your network connection.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            break
        case CLError.Denied.rawValue:
            var alert : UIAlertView = UIAlertView(title: "Network Error", message: "Please check your network connection.", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            break
        default:
            break
        }
    }
    
    func applicationEnterBackground() {
        println("application enters background")
//        var locationManager = CLLocationManager()
        
//        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
//        locationManager.distanceFilter = kCLDistanceFilterNone
        
//        locationManager.distanceFilter = 500.0
        
        locationManager.stopMonitoringSignificantLocationChanges()
        
        locationManager.requestAlwaysAuthorization() //for iOS 8
        
        locationManager.startMonitoringSignificantLocationChanges()
        
        //Use the BackgroundTaskManager to manage all the background Task
//        self.shareModel!.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
//        self.shareModel?.bgTask?.beginNewBackgroundTask()
//        
    }
    
    func restartLocationUpdates() {
        println("restartLocationUpdates")
        
        configuration = Configuration()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = configuration.desiredAccuracy //kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = configuration.distanceFilter
        
        //        if(IS_OS_8_OR_LATER) {
        locationManager.requestAlwaysAuthorization()
        //        }
        locationManager.startMonitoringSignificantLocationChanges()
//        let time : NSTimeInterval = configuration.timeToSave
//        var locationUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(time, target: self,
//            selector: "significantUpdateLocationRS", userInfo: nil, repeats: true)
    }
    
    func significantUpdateLocationRS() {
        println("updating location to server")
        outputList()
        //        locationCollector.updateLocationToServer()
    }
    
    
    func startUpdatingLocation() {
        println("startUpdatingLocation")
        locationManager.startUpdatingLocation()
    }
    
    func startLocationCollecting() {
        println("SignificantChangeLocationCollector - startLocationCollecting")
        
        if (CLLocationManager.locationServicesEnabled() == false) {
            println("locationServicesEnabled false")
            var servicesDisabledAlert : UIAlertView = UIAlertView(title: "Location Services Disabled", message: "You currently have all location services for this device disabled", delegate: nil, cancelButtonTitle: "OK")
            servicesDisabledAlert.show()
        } else {
            var authorizationStatus = CLLocationManager.authorizationStatus()
            
            if ( authorizationStatus == CLAuthorizationStatus.Restricted || authorizationStatus == CLAuthorizationStatus.Denied) {
                println("authorizationStatus failed")
            } else {
                println("authorizationStatus authorized")
//                var locationManager : CLLocationManager = LocationCollector.sharedLocationManager()!
//                locationManager.delegate = self;
//                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
//                locationManager.distanceFilter = 500.0;

                
                //                if(IS_OS_8_OR_LATER) {

                //                }
                locationManager.startMonitoringSignificantLocationChanges()
            }
        }
    }
    
    func stopLocationCollecting() {
        println("stopLocationTracking");
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func toJSON(myBestLocation: NSMutableDictionary) -> JSON {
        var scannedResults: [[String : CLLocationDegrees]] = []
        for (key, value) in myBestLocation {
            var newDict = [key as! String : value as! CLLocationDegrees]
            println("Key \(key) value \(value)")
            scannedResults.append(newDict)
        }
        
        //Scanned results needs an array of dictionaries.
        var json:JSON = [
            "userid" : collectorInformation.userid,
            "deviceid" : collectorInformation.deviceid,
            //            "sampleLength" : 5
            //            "sensorType": collectorInformation.sensorType,
            //            "sampleStartTime" : collectorInformation.senseStartTime.description,
            "scannedResults" : scannedResults
        ]
        
        return json
    }
    
    
    func updateLocationToServer() {

    }
}
