//
//  InformationSender.swift
//  iCollector
//
//  Created by Nhan Nguyen on 3/10/15.
//

import Foundation
import UIKit

class InformationSender: NSObject {
    var device: UIDevice
    var reachability: Reachability
    var activityCollector = ActivityCollector()
    
    override init() {
        device = UIDevice()
        reachability = Reachability.reachabilityForInternetConnection()
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "checkBatteryState", name: UIDeviceBatteryStateDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability) //notify when the network is changed
        reachability.startNotifier()
    }
    

    
    func getBatteryStatus() {
        if (!device.batteryMonitoringEnabled) {
            device.batteryMonitoringEnabled = true
            
            var currentBatteryLevel = device.batteryLevel
            
            println("we can monitor battery")
            var currentState = device.batteryState
            if (currentState == UIDeviceBatteryState.Charging) {
//                var alert : UIAlertView = UIAlertView(title: "Alert", message: "You are charging your phone", delegate: self, cancelButtonTitle: "OK")
//                alert.show()
                println("You are charging your phone")
            }
            if (currentState == UIDeviceBatteryState.Full) {
//                var alert : UIAlertView = UIAlertView(title: "Alert", message: "The battery is full", delegate: self, cancelButtonTitle: "OK")
//                alert.show()
                println("The battery is full")
            }
            if (currentState == UIDeviceBatteryState.Unplugged) {
                //                var alert : UIAlertView = UIAlertView(title: "Alert", message: "The battery is full", delegate: self, cancelButtonTitle: "OK")
                //                alert.show()
                println("Unplugged")
            }
            if (currentState == UIDeviceBatteryState.Unknown) {
                //                var alert : UIAlertView = UIAlertView(title: "Alert", message: "The battery is full", delegate: self, cancelButtonTitle: "OK")
                //                alert.show()
                println("Unknown")
            }
            
        }
    }
    
    func checkBatteryState() {
        device.batteryMonitoringEnabled = true
        
        var currentState = device.batteryState
        if (currentState == UIDeviceBatteryState.Charging) {
            var alert : UIAlertView = UIAlertView(title: "Alert", message: "You are charging your phone", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            println("You are charging your phone")
//            sendInformationToServer()
            var subdirectoryName = Util.getDataDirectoryName()
            var fileName = Util.getDataFileName() + "-battery.txt"
            Util.saveData("battery", path:fileName, subdirectory:subdirectoryName)
//            println("Read from file \(fileName) of directory \(subdirectoryName)")
        }
    }
    
    
    func reachabilityChanged(note: NSNotification) {
        let reachability = note.object as! Reachability
        println("Network changed")
        let dataOfDate = Util.getSentDirectory() + "/" + Util.getDataDirectoryName() + ".txt"
//        println("dataOfDate \(dataOfDate)")
        
        if reachability.isReachable() {
            if (reachability.isReachableViaWiFi()) {
                println("Reachable via WiFi")
                 //commented for simulator
                if (!NSFileManager.defaultManager().fileExistsAtPath(Util.getActivityFileName())) {
                   
                    activityCollector.getActivityData({(successActivity) in
                        if (successActivity!) {
                             println("Got Activity")
                            if (!Util.isSent(dataOfDate)) {
                                println("Data is not sent")
                                if (NSFileManager.defaultManager().fileExistsAtPath(Util.getActivityFileName())) {
                                    //                    NSThread.sleepForTimeInterval(5)
                                    if (Util.zipFile(Util.getYesterdayDataDirectoryName())) {
                                        println("here")
                                        Util.sendDataToServer({(success) in
                                            if (success!) {
                                                Util.saveData("sent", path: Util.getDataDirectoryName() + ".txt", subdirectory: "sent")
                                                println("Saving data to \(dataOfDate)")
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    })
                } else {
                    println("Do not need to get Activity Data")
                }
            
                if (Util.isSent(dataOfDate)) {
                    println("Data is sent")
                } else {
                    println("Data is not sent")
                    if (NSFileManager.defaultManager().fileExistsAtPath(Util.getActivityFileName())) { //commented for simulator
//                    NSThread.sleepForTimeInterval(5)
                        if (Util.zipFile(Util.getYesterdayDataDirectoryName())) {
//                            println("here")
                            Util.sendDataToServer({(success) in
                                if (success!) {
                                    Util.saveData("sent", path: Util.getDataDirectoryName() + ".txt", subdirectory: "sent")
//                                    println("Saving data to \(dataOfDate)")
                                    println("Sent data succesfully")
                                }
                            })
                        }
                    }
                }
                   
              
            }
        } else {
        }
    }
    
    
    func getData(fileName : String) -> NSData { //depracated

        let fileData = NSMutableData(contentsOfFile: fileName)//NSTemporaryDirectory().stringByAppendingPathComponent(fileName))
        if fileData == nil {
        return NSMutableData()
        }
        
        return fileData!
    }
    
    func sendDataToServer() {
        let filePath = Util.getFullDataDirectoryPath() + ".zip" //the abosulote path of the data file
        var fileData : NSData?
        if let fileContents = NSFileManager.defaultManager().contentsAtPath(filePath) {
            fileData = fileContents  //read the content of the file
        }
        
        let fileName = Util.getDataDirectoryName() + ".zip" //get the name of the file
        
        let boundaryConstant = "Boundary-daef4acbb6d88e20"
        let mimeType = "application/zip'"
        let fieldName = "file"  //change this filedName as in the php file
        
        let contentType = "multipart/form-data; boundary=" + boundaryConstant
        var error: NSError?
        let boundaryStart = "--\(boundaryConstant)\r\n"
        let boundaryEnd = "--\(boundaryConstant)--\r\n"
        let contentDispositionString = "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
        let contentTypeString = "Content-Type: \(mimeType)\r\n\r\n"
        
        let requestBodyData : NSMutableData = NSMutableData()
        requestBodyData.appendData(boundaryStart.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(fileData!)
        requestBodyData.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        requestBodyData.appendData(boundaryEnd.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        var URL: NSURL = NSURL(string: "http://137.99.10.188")!  //"http://posttestserver.com")! //ip of server, we can use posttestserver.com to test
        
        var mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent("postios.php")) //name of the php file
        mutableURLRequest.HTTPMethod = "POST"
        
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = requestBodyData
        println("Sent \(filePath) sucessfully")
        let param = ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0

    }
    
    func sendInformationToServer() {
        println("Sending Information")
        if (reachability.isReachable()) {
            if (reachability.isReachableViaWiFi()) {
                
               
            } else {
                println("Reachable via Cellular")
            }
        } else {
            println("No Internet Connection")
        }

    }
}
