//
//  LocationShareModel.swift
//  iCollector
//
//  Created by Nhan Nguyen on 2/18/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import Foundation

class LocationShareModel: NSObject {
    var bgTask : BackgroundTaskManager?
    var timer : NSTimer?
    var delay10Seconds : NSTimer?
    var myLocationArray : NSMutableArray?
    
    var previousLongtitue = Double()
    var previousLattitue = Double()
    
    func sharedModel()-> AnyObject {
        struct Static {
            static var sharedMyModel : AnyObject?
            static var onceToken : dispatch_once_t = 0
        }
        dispatch_once(&Static.onceToken) {
            Static.sharedMyModel = LocationShareModel()
        }
        return Static.sharedMyModel!
    }
}