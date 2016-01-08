//
//  BackgroundTaskManager.swift
//  iCollector
//
//  Created by Nhan Nguyen on 2/18/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import Foundation
import UIKit

class BackgroundTaskManager: NSObject {
    
    var bgTaskIdList : NSMutableArray?
    var masterTaskId : UIBackgroundTaskIdentifier?
    
    override init() {
        super.init()
        self.bgTaskIdList = NSMutableArray()
        self.masterTaskId = UIBackgroundTaskInvalid
    }
    
     class func sharedBackgroundTaskManager() -> BackgroundTaskManager? {
        struct Static {
            static var sharedBGTaskManager : BackgroundTaskManager?
            static var onceToken : dispatch_once_t = 0
        }
        dispatch_once(&Static.onceToken) {
            Static.sharedBGTaskManager = BackgroundTaskManager()
        }
        return Static.sharedBGTaskManager
    }
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier? {
        var application = UIApplication.sharedApplication()
        var bgTaskId = UIBackgroundTaskInvalid
        
        if application.respondsToSelector("beginBackgroundTaskWithExpirationHandler") {
        
            bgTaskId = application.beginBackgroundTaskWithExpirationHandler({ //request some additional execution time
                //bgTaskId = a unique token to associate with the corresponding task
                print("background task \(bgTaskId as Int) expired\n")
            })
        
            if ( self.masterTaskId == UIBackgroundTaskInvalid )
            {
                self.masterTaskId = bgTaskId
                print("started master task \(self.masterTaskId)\n")
            }
            else
            {
                //add this id to our list
                print("started background task \(bgTaskId as Int)\n")
                self.bgTaskIdList!.addObject(bgTaskId)
                self.endBackgroundTasks()
            }
        }
        
        return bgTaskId
    }
    
    func endBackgroundTasks() {
        drainBGTaskList(false)
    }
    
    func endAllBackgroundTasks() {
        drainBGTaskList(true)
    }
    
    func drainBGTaskList(all: Bool) {
        //mark end of each of our background task
        var application = UIApplication.sharedApplication()
        
        if application.respondsToSelector("endBackgroundTask") {
            var count = self.bgTaskIdList!.count
            for (var i = (all == true ? 0:1); i < count; i++ )
            {
                var bgTaskId = self.bgTaskIdList!.objectAtIndex(0) as! Int
                print("ending background task with id \(bgTaskId as Int)\n")
                application.endBackgroundTask(bgTaskId) //let the system know that it is finished and can be suspended, call method with the corresponding token to let the system know that the task is complete
                self.bgTaskIdList!.removeObjectAtIndex(0)
            }
            if self.bgTaskIdList!.count > 0
            {
               print("kept background task id \(self.bgTaskIdList!.objectAtIndex(0))\n")
            }
            if all == true
            {
                print("no more background tasks running\n")
                application.endBackgroundTask(self.masterTaskId!) //let the system know that it is finished and can be suspended, call method with the corresponding token to let the system know that the task is complete
                self.masterTaskId = UIBackgroundTaskInvalid
            }
            else
            {
                print("kept master background task id \(self.masterTaskId)\n")
            }
        }
    }
}