//
//  LocationCollector.swift
//  iCollector
//
//  Created by Nhan Nguyen on 2/15/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let LATITUDE = "latitude"
let LONGITUDE = "longitude"
let ACCURACY = "theAccuracy"
let theDesiredAccuracy = kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBestForNavigation

class LocationCollector: NSObject, CLLocationManagerDelegate {
    
    var myLastLocation : CLLocationCoordinate2D?
    var myLastLocationAccuracy : CLLocationAccuracy?
    
    var myLocation : CLLocationCoordinate2D?
    var myLocationAccuracy : CLLocationAccuracy?
    
    var dateFormatter = NSDateFormatter()
    
//    var locationManager : CLLocationManager
    
    var shareModel : LocationShareModel?
    
    var collectorInformation = CollectorInformation()
    
    func sharedLocationManager() -> CLLocationManager {
        var _locationManager = CLLocationManager()
        
        _locationManager.desiredAccuracy = theDesiredAccuracy
        return _locationManager
    }
    
    override init() {
        super.init()
        self.shareModel = LocationShareModel()
        self.shareModel!.myLocationArray = NSMutableArray()
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    class func sharedLocationManager()->CLLocationManager? {
        
        struct Static {
            static var _locationManager : CLLocationManager?
        }
        
        objc_sync_enter(self)
        if Static._locationManager == nil {
            Static._locationManager = CLLocationManager()
            Static._locationManager!.desiredAccuracy = theDesiredAccuracy
        }
        
        objc_sync_exit(self)
        return Static._locationManager!
    }
    
    func output(location : CLLocation) {
        var result = toJSON(location).description + "\n"
//        println(result)
        var subdirectoryName = Util.getDataDirectoryName()
        var fileName = "locationAccurate.txt" //Util.getDataFileName() +
        Util.saveData(result, path:fileName, subdirectory:subdirectoryName)
        //        println("Save data to file \(fileName) of directory \(subdirectoryName)")
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
                "latitude" : String(format: "%.10f", location.coordinate.latitude),
                "longtitude" : String(format: "%.10f", location.coordinate.longitude),
                "bssid" : bSSID
            ]
            return json
       
        
        
    }
    
    var count = 0
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("getting Location \(count++)")
        
        var realLocations: [CLLocation] = locations as! [CLLocation]
        
        for(var i=0; i < realLocations.count; i++){
            var newLocation : CLLocation = realLocations[i]
//            var newLocation = realLocations[i]
            var theLocation = newLocation.coordinate //CLLocationCoordinate2D
            var theAccuracy = newLocation.horizontalAccuracy //CLLocationAccuracy
            
            var locationAge = -newLocation.timestamp.timeIntervalSinceNow //NSTimeInterval, might not have -
            
            if (locationAge > 30.0)
            {
                continue;
            }
            
            
            //Select only valid location and also location with good accuracy
            //need to check wheter newLocation is valid
            if theLocation.latitude != self.shareModel!.previousLattitue && theLocation.longitude != self.shareModel!.previousLongtitue &&
                theAccuracy > 0.0 && theAccuracy < 2000.0 &&
                theLocation.latitude != 0.0 && theLocation.longitude != 0.0 {
                    
                    self.myLastLocation = theLocation
                    self.myLastLocationAccuracy = theAccuracy
                    output(newLocation)
                    var dict = NSMutableDictionary() // NSMutableDictionary alloc]init];
                    
                    dict.setObject(theLocation.latitude as CLLocationDegrees, forKey: LATITUDE)
                    var temp = theLocation.latitude // stringWithFormat:@"%f", theLocation.latitude];
//                    println("\(temp)")
                    dict.setObject(theLocation.longitude as CLLocationDegrees, forKey: LONGITUDE)
                    temp = theLocation.longitude
//                    println("\(temp)")
                    dict.setObject(theAccuracy, forKey: ACCURACY)
                    
                    //Add the vallid location with good accuracy into an array
                    //Every 1 minute, I will select the best location based on accuracy and send to server
                    
                    self.shareModel!.myLocationArray!.addObject(dict)
                    self.shareModel!.previousLattitue = theLocation.latitude
                    self.shareModel!.previousLongtitue = theLocation.longitude
            }
        }
        
        //If the timer still valid, return it (Will not run the code below)
        if (self.shareModel!.timer != nil) {
            return;
        }
        
        self.shareModel!.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        self.shareModel!.bgTask!.beginNewBackgroundTask()
        
        //Restart the locationMaanger after 1 minute
        self.shareModel!.timer = NSTimer.scheduledTimerWithTimeInterval(120, target: self, selector: Selector("restartLocationUpdates"), userInfo: nil, repeats: false)

        
        //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
        //The location manager will only operate for 10 seconds to save battery
        if (self.shareModel!.delay10Seconds != nil) {
            self.shareModel!.delay10Seconds!.invalidate()
            self.shareModel!.delay10Seconds = nil;
        }
        
        self.shareModel!.delay10Seconds = NSTimer.scheduledTimerWithTimeInterval(10, target:self,
            selector:Selector("stopLocationDelayBy10Seconds"), userInfo:nil, repeats:false)
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
        println("applicationEnterBackground")
        var locationManager : CLLocationManager = LocationCollector.sharedLocationManager()!
        locationManager.delegate = self;
        locationManager.desiredAccuracy = theDesiredAccuracy
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        locationManager.requestAlwaysAuthorization() //for iOS 8
        
        locationManager.startUpdatingLocation()
        
        //Use the BackgroundTaskManager to manage all the background Task
        self.shareModel!.bgTask = BackgroundTaskManager.sharedBackgroundTaskManager()
        self.shareModel?.bgTask?.beginNewBackgroundTask()
        
    }
    
    func restartLocationUpdates() {
        println("restartLocationUpdates")
        
        if (self.shareModel?.timer != nil) {
            self.shareModel?.timer?.invalidate()
            self.shareModel!.timer = nil;
        }
        
        var locationManager = LocationCollector.sharedLocationManager()!
        locationManager.delegate = self;
        locationManager.desiredAccuracy = theDesiredAccuracy
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        //        if(IS_OS_8_OR_LATER) {
        locationManager.requestAlwaysAuthorization()
        //        }
        locationManager.startUpdatingLocation()
    }
    
    
    func startLocationCollecting() {
        println("startLocationCollecting")
        
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
                var locationManager : CLLocationManager = LocationCollector.sharedLocationManager()!
                locationManager.delegate = self;
                locationManager.desiredAccuracy = theDesiredAccuracy
                locationManager.distanceFilter = kCLDistanceFilterNone;
                
                //                if(IS_OS_8_OR_LATER) {
                locationManager.requestAlwaysAuthorization()
                //                }
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func stopLocationCollecting() {
        println("stopLocationTracking");
        
        if (self.shareModel!.timer != nil) {
            self.shareModel?.timer?.invalidate()
            self.shareModel!.timer = nil
        }
        
        var locationManager : CLLocationManager = LocationCollector.sharedLocationManager()!
        locationManager.stopUpdatingLocation()
    }
    
    func stopLocationDelayBy10Seconds() {
        var locationManager : CLLocationManager = LocationCollector.sharedLocationManager()!
        locationManager.stopUpdatingLocation()
        
        println("locationManager stop Updating after 10 seconds")
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
        println("updateLocationToServer")
        
        // Find the best location from the array based on accuracy
         var myBestLocation = NSMutableDictionary()
        
        for(var i=0 ; i < self.shareModel!.myLocationArray!.count; i++){
            var currentLocation = self.shareModel!.myLocationArray!.objectAtIndex(i) as! NSMutableDictionary
            
            if (i==0) {
                myBestLocation = currentLocation
            }
            else{
                if (currentLocation.objectForKey(ACCURACY) as! Float) <=
                    (myBestLocation.objectForKey(ACCURACY) as! Float) {
                    myBestLocation = currentLocation;
                    println("count \(currentLocation.count)")
                }
            }
        }
        print("My Best location \(myBestLocation)\n")
        
        //If the array is 0, get the last location
        //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
        if (self.shareModel!.myLocationArray!.count == 0)
        {
            print("Unable to get location, use the last known location\n")
            self.myLocation = self.myLastLocation;
            self.myLocationAccuracy = self.myLastLocationAccuracy;
            
        } else {
//            var theBestLocation : CLLocationCoordinate2D?
//            theBestLocation!.latitude = myBestLocation.objectForKey(LATITUDE) as CLLocationDegrees
//            theBestLocation!.longitude = myBestLocation.objectForKey(LONGITUDE) as CLLocationDegrees
            var lat : CLLocationDegrees = myBestLocation.objectForKey(LATITUDE) as! CLLocationDegrees
            var lon : CLLocationDegrees = myBestLocation.objectForKey(LONGITUDE) as! CLLocationDegrees
            var theBestLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            self.myLocation = theBestLocation;
            self.myLocationAccuracy = myBestLocation.objectForKey(ACCURACY) as! CLLocationAccuracy!
        }
        
        print("Send to server: latitude \(self.myLocation?.latitude) longitude \(self.myLocation?.longitude) accuracy \(self.myLocationAccuracy)\n")
        
        self.toJSON(myBestLocation)
        
        //TODO: Your code to send the self.myLocation and self.myLocationAccuracy to your server
        
        //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
        self.shareModel!.myLocationArray!.removeAllObjects()
        self.shareModel!.myLocationArray = nil
        self.shareModel!.myLocationArray = NSMutableArray()
    }
}
