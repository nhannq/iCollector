//
//  ActivityCollector.swift
//  iCollector
//
//  Created by Nhan Nguyen on 3/16/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//


//http://www.knowyourmobile.com/apple/apple-iphone-5s/21339/iphone-5s-m7-co-processor-explored-everything-you-need-know

import Foundation
import CoreMotion

class ActivityCollector: NSObject {
    var activityManager : CMMotionActivityManager
    
    var dateFormatter = NSDateFormatter()
    
    var myActivityArray : NSMutableArray?
    
    var collectorInformation = CollectorInformation()
    
    override init() {
        dateFormatter.dateFormat = "MM-dd-yyyy hh:mm:ss a"
//        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        activityManager = CMMotionActivityManager()
        myActivityArray = NSMutableArray()
        super.init()
    }
    
    /**

    */
    func outputList() {
        var result = toJSON().description
        //println(result)
        var subdirectoryName = Util.getYesterdayDataDirectoryName() //Util.getDataDirectoryName()
        var fileName = "activity.json" //Util.getDataFileName() + 
        Util.saveData(result, path:fileName, subdirectory:subdirectoryName)
        println("Read from file \(fileName) of directory \(subdirectoryName)")
        
//        var temporaryDirectory:String? = NSTemporaryDirectory();
        
//        var tempDir =  NSURL(fileURLWithPath: temporaryDirectory!)!.path! + "/"
        
        let data = Util.loadData(fileName, subdirectory: subdirectoryName)
        if (data != "") {
//            println(data)
        } else {
            println("Cannot read data from file")
        }
        
//        if (Util.deleteData(subdirectoryName)) {
//            println("deleted \(tempDir + subdirectoryName)")
//        }
    }
    
    func toJSON() -> JSON {
        var scannedResults: [[String : AnyObject]] = []
        for(var i=0 ; i < self.myActivityArray!.count; i++){
            var activity = self.myActivityArray!.objectAtIndex(i) as! NSMutableDictionary
            var newDict = ["activity: " : activity.objectForKey("activity") as! String,
                "confidence: " : activity.objectForKey("confidence") as! String,
                "startTime" : activity.objectForKey("time") as! String]
            scannedResults.append(newDict)
        }
        self.myActivityArray!.removeAllObjects()
        self.myActivityArray = nil
        self.myActivityArray = NSMutableArray()
        
        //Scanned results needs an array of dictionaries.
        var json:JSON = [
            "userid" : collectorInformation.userid,
            "deviceid" : collectorInformation.deviceid,
            "dataType" : "activity",
            "scannedResults" : scannedResults
        ]
        
        return json
    }
    typealias CompletionHandler = (success: Bool?) -> Void
    func getActivityData(aHandler: CompletionHandler?) {
        if (CMPedometer.isStepCountingAvailable()) {
            println("Step Counting is Available")
        }
        if (CMPedometer.isFloorCountingAvailable()) {
            println("Floor Counting is Available")
        }
        if (CMPedometer.isDistanceAvailable()) {
            println("Distance is Available")
        }
        
        let nsDateComponents = NSDateComponents()
        let cal = NSCalendar.currentCalendar()
        let flags: NSCalendarUnit = .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond //get current hour, minute, second
        let todayComponents = cal.components(flags, fromDate: NSDate())
        
        nsDateComponents.hour = -todayComponents.hour
        nsDateComponents.minute = -todayComponents.minute
        nsDateComponents.second = -todayComponents.second
        
        var fileDateFormatter = NSDateFormatter()
        fileDateFormatter.dateFormat = "MM-dd-yyyy hh-mm-ss a"
        fileDateFormatter.timeZone = NSTimeZone.systemTimeZone()
        
        let today = NSCalendar.currentCalendar().dateByAddingComponents(nsDateComponents, toDate: NSDate(), options: NSCalendarOptions(0)) //get mid night of yesterday
//        println("today \(fileDateFormatter.stringFromDate(today!))")
        
        nsDateComponents.day = -1
        let yesterday = NSCalendar.currentCalendar().dateByAddingComponents(nsDateComponents, toDate: NSDate(), options: NSCalendarOptions(0)) //get mid night of two days ago
//        println("yesterday \(fileDateFormatter.stringFromDate(yesterday!))")
        
        
        
        if CMMotionActivityManager.isActivityAvailable() {
            println("get activity data")
            let motionHandlerQueue = NSOperationQueue.mainQueue() //NSOperationQueue()
            let timeInterval = 24 * 3600 as NSTimeInterval //NSTimeInterval is always second deprecated
          
            activityManager.queryActivityStartingFromDate(yesterday!,
                toDate: today, toQueue: motionHandlerQueue) {
//            activityManager.queryActivityStartingFromDate(NSDate(timeIntervalSinceNow: -timeInterval),
//                toDate: NSDate(), toQueue: motionHandlerQueue) {
                    (activities, error) in
                    if error != nil {
                        println("There was an error retrieving the motion results: \(error)")
                    }
                    
                    var realActivities = activities as! [CMMotionActivity]
                    println("There are \(realActivities.count)")

                    for (var i = 0; i < realActivities.count; i++) {
                        var activity = realActivities[i]
                        var action = ""
                        if (activity.stationary == true) {action += "stationary "}
                        if (activity.walking == true) {action += " walking"}
                        if (activity.running == true) {action += " running"}
                        if (activity.automotive == true) {action += " automotive"}
                        if (activity.cycling == true) {action += " cycling"} // >= iphone 6
                        if (activity.unknown == true) {action += " unknown"}
                        
                        var confidence = ""
                        if (action != "") {
                            switch activity.confidence {
                            case CMMotionActivityConfidence.High:
                                confidence = "hight"
                            case CMMotionActivityConfidence.Medium:
                                confidence = "medium"
                            case CMMotionActivityConfidence.Low:
                                confidence = "low"
                            }
                            
                            var dict = NSMutableDictionary() // NSMutableDictionary alloc]init];
                            dict.setObject(action as String, forKey: "activity")
                            println("\(action) time \(self.dateFormatter.stringFromDate(activity.startDate))")
                            dict.setObject(confidence as String, forKey: "confidence")

                            dict.setObject(self.dateFormatter.stringFromDate(activity.startDate), forKey: "time")
                            self.myActivityArray?.addObject(dict)
                        }
                    }
                    self.outputList()
                    aHandler?(success: true)
            }
//            return true
        } else {
            aHandler?(success: false)
//            return false
        }
    }
}