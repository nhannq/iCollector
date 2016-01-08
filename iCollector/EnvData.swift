////
////  EnvData.swift
////  iCollector
////
////  Created by Nhan Nguyen on 3/19/15.
////  Copyright (c) 2015 University of Connecticut. All rights reserved.
////
//
//import SystemConfiguration
//
//class EnvData: NSObject {
//    
//    class func getSSID() -> String {
//        
//        var currentSSID = ""
//        
//        let interfaces = CNCopySupportedInterfaces()
//        
//        if interfaces != nil {
//            
//            let interfacesArray = interfaces.takeRetainedValue() as [String]
//            
//            if interfacesArray.count > 0 {
//                
//                let interfaceName = interfacesArray[0] as String
//                
//                let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)
//                
//                if unsafeInterfaceData != nil {
//                    
//                    let interfaceData = unsafeInterfaceData.takeRetainedValue() as Dictionary!
//                    
//                    currentSSID = interfaceData["SSID"] as String
//                    
//                } else {
//                    
//                    currentSSID = ""
//                }
//                
//            } else {
//                
//                currentSSID = ""
//            }
//            
//        } else {
//            
//            currentSSID = ""
//        }
//        
//        return currentSSID
//    }
//}
