//
//  Configuration.swift
//  iCollector
//
//  Created by Nhan Nguyen on 3/18/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import Foundation
import CoreLocation

class Configuration: NSObject {
    var distanceFilter : CLLocationDistance
    var desiredAccuracy: CLLocationAccuracy
    var numberOfSamplesToSave : Int
    var timeToSave : NSTimeInterval
    var serverIP : String
    
    override init() {
        distanceFilter = kCLDistanceFilterNone //Use the value kCLDistanceFilterNone to be notified of all movements
        desiredAccuracy = kCLLocationAccuracyBest //kCLLocationAccuracyHundredMeters //kCLLocationAccuracyBestForNavigation //kCLLocationAccuracyNearestTenMeters //kCLLocationAccuracyBest
        numberOfSamplesToSave = 10
        timeToSave = 120.0 //second - 3 minutes
        serverIP = ""
        super.init()
    }
}