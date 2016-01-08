//
//  Util.swift
//  iCollector
//
//  Created by Nhan Nguyen on 3/18/15.
//

import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork

class Util {
    typealias CompletionHandler = (success: Bool?) -> Void
//    var configuration = Configuration()
   
    class func sendDataToServer(aHandler: CompletionHandler?) {
        let filePath = Util.getFullDataDirectoryPath() + ".zip" //the abosulote path of the data file
        var fileData : NSData?
        if let fileContents = NSFileManager.defaultManager().contentsAtPath(filePath) {
            fileData = fileContents  //read the content of the file
        }
        
        let fileName = Util.getYesterdayDataDirectoryName() + ".zip"  //Util.getDataDirectoryName() + ".zip" //get the name of the file

        
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
        
        var URL: NSURL = NSURL(string: "http://137.99.10.188")! 
        
        var mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent("postios.php")) //name of the php file
        mutableURLRequest.HTTPMethod = "POST"
        
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = requestBodyData
        
        let param = ParameterEncoding.URL.encode(mutableURLRequest, parameters: nil).0
        
        request(param).responseString { (request, response, string, error) in
            //println("request \(request)")
            //println(" response \(response)")
            if (response?.statusCode == 200) {
                println("Sent \(filePath) sucessfully")
            }
            //println(" error \(error)")
            println("Message from Server \(string!)")
            let resultStr = string!
        
            if (resultStr == "success") {
//                println("WE ARE GOOD")
                aHandler?(success: true)
            } else {
                aHandler?(success: false)
            }
        }
    }
    
    class func getDeviceInformation() {
        //        println("name: \(device.name)")
        //        println("systemName: \(device.systemName)")
        //        println("systemVersion: \(device.systemVersion)")
        //        println("UUID: \(device.identifierForVendor.UUIDString)")
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey("ApplicationUniqueIdentifier") == nil {
            let UUID = NSUUID().UUIDString
            userDefaults.setObject(UUID, forKey: "ApplicationUniqueIdentifier")
            userDefaults.synchronize()
        }
        //        let UUID = userDefaults.objectForKey("ApplicationUniqueIdentifier") as! String
        //        println("UUID \(UUID)")
    }
    
    class func getUUID() -> String {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let UUID = userDefaults.objectForKey("ApplicationUniqueIdentifier") as! String
//        println("UUID get anywhere \(UUID)")
        return UUID
    }
    
    //Source code based on https://github.com/sketchytech
    
    class func getDataFileName() -> String {
        var fileDateFormatter = NSDateFormatter()
        fileDateFormatter.dateFormat = "hh-mm-ss-a"
        fileDateFormatter.timeZone = NSTimeZone.systemTimeZone()
        var dataFileName = fileDateFormatter.stringFromDate(NSDate())
        return dataFileName
    }
    
    class func getDataDirectoryName() -> String {
        var fileDateFormatter = NSDateFormatter()
        fileDateFormatter.dateFormat = "MMddyyyy"
        fileDateFormatter.timeZone = NSTimeZone.systemTimeZone()
        var subdirectoryName = fileDateFormatter.stringFromDate(NSDate())
//        if (configuration.UUID == "") {
//            configuration.getUUID()
//        }
        var uuid = getUUID()
        if (uuid == "") {
            getDeviceInformation()
            uuid = getUUID()
        }
//        uuid = "iOS"
        return uuid + "_data_" + subdirectoryName
    }
    
    class func getYesterdayDataDirectoryName() -> String {
        let nsDateComponents = NSDateComponents()
        let cal = NSCalendar.currentCalendar()
        let flags: NSCalendarUnit = .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond //get current hour, minute, second
        let todayComponents = cal.components(flags, fromDate: NSDate())
        
        nsDateComponents.hour = -todayComponents.hour
        nsDateComponents.minute = -todayComponents.minute
        nsDateComponents.second = -todayComponents.second
        
        var fileDateFormatter = NSDateFormatter()
        fileDateFormatter.dateFormat = "MMddyyyy"
        fileDateFormatter.timeZone = NSTimeZone.systemTimeZone()
        
        nsDateComponents.day = -1
        let yesterday = NSCalendar.currentCalendar().dateByAddingComponents(nsDateComponents, toDate: NSDate(), options: NSCalendarOptions(0)) //get mid night of two days ago
//        println("yesterday \(fileDateFormatter.stringFromDate(yesterday!))")
        var uuid = getUUID()
        if (uuid == "") {
            getDeviceInformation()
            uuid = getUUID()
        }
//        uuid = "iOS"
        return uuid + "_data_" + fileDateFormatter.stringFromDate(yesterday!)
    }
    
    class func getActivityFileName() -> String {
        return getFullDataDirectoryPath() + "/activity.json"
    }
    
    class func getFullDataDirectoryPath() -> String {
        return Util.applicationDirectory().path! + "/" + getYesterdayDataDirectoryName() //getDataDirectoryName()
    }
    
    class func listFilesFromDocumentsFolder(dirPath: String) -> [String] {
        var theError = NSErrorPointer()
        let fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(dirPath, error: theError)
        return fileList as! [String]
    }
    
    class func zipFile(subdirectoryName: String)-> Bool {
        var archiveError: NSError? = NSError()
        let archiveName = subdirectoryName
        let archivePath = Util.applicationDirectory().path!+"/" + archiveName + ".zip" //NSTemporaryDirectory().stringByAppendingPathComponent("\(archiveName).zip")
        println(archivePath)
        if (!NSFileManager.defaultManager().fileExistsAtPath(archivePath)) {
            // Creating the archive here. Passing nil for the error pointer does not really make a difference and we prefer to handle the errors.
            let url = NSURL(fileURLWithPath: archivePath)
            var archive = ZZArchive(URL: url, options:[ZZOpenOptionsCreateIfMissingKey: true], error: &archiveError)
        
            var updateError = NSErrorPointer()
            // Attempting to add entries to the archive. This is where we see the crash.
        
            var archiveItems = NSMutableArray()
        
        // First add the folder
        //        fileName = "1.txt"
        
//        archiveItems.addObject(ZZArchiveEntry(directoryName: "\(archiveName)/"))
        
            let directory = Util.applicationDirectory().path!+"/" + archiveName
            let fileManager:NSFileManager = NSFileManager.defaultManager()
            if (NSFileManager.defaultManager().fileExistsAtPath(directory)) {
                let fileList = listFilesFromDocumentsFolder(directory)
                for (var i = 0; i < fileList.count; i++) {
                    if fileManager.fileExistsAtPath(fileList[i]) != true {
                        var fileName = fileList[i]
                        println(fileName)
    //                  archiveItems.addObject(ZZArchiveEntry(fileName: "\(archiveName)/\(fileName)", compress: true,
                        archiveItems.addObject(ZZArchiveEntry(fileName: "\(fileName)", compress: true,
                            dataBlock: { (NSErrorPointer) -> NSData! in
                                let fileData = NSMutableData(contentsOfFile: directory + "/" + fileName)//NSTemporaryDirectory().stringByAppendingPathComponent(fileName))
                                if fileData == nil {
                                    return NSMutableData()
                                }
                            
                            return fileData
                        }))
                    }
                }
            
                let result = archive.updateEntries(archiveItems as [AnyObject], error: updateError)
                return result
            }
        }
        return false
    }
    
    class func getNetWorkInfo() -> [String] {
        println("getNetWorkInfo")
        var result = [String]()
        let interfaces = CNCopySupportedInterfaces()
        if interfaces == nil {
            return result
        }
        
        let interfacesArray = interfaces.takeRetainedValue() as! [String]
        if interfacesArray.count <= 0 {
            return result
        }
        
        let interfaceName = interfacesArray[0] as String
        let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)
        if unsafeInterfaceData == nil {
            return result
        }
        
        let interfaceData = unsafeInterfaceData.takeRetainedValue() as Dictionary!
        
        let componentArray = interfaceData.keys.array
        
//        println("count \(componentArray.count)")
        for (var i = 0; i < componentArray.count; i++) {
            var key = componentArray[i] as! String
//            println(key)
        }
        
        //http://www.juniper.net/documentation/en_US/network-director1.5/topics/concept/wireless-ssid-bssid-essid.html
        println(interfaceData["SSIDDATA"])
        println(interfaceData["BSSID"])  //basic service set identifier = AP MAC Address
        result.append(interfaceData["SSID"] as! String)
        var bSSID = interfaceData["BSSID"] as! String
       
        result.append(bSSID)
        return result //service set ID = name of network
    }
    
   
    class func deleteData(subdirectory:String) -> Bool
    {
        // Remove unnecessary slash if need
        var newSubdirectory:String? = self.stripSlashIfNeeded(subdirectory)
        
        // Create generic beginning to file delete path
        var deletePath = self.applicationDirectory().path!+"/"
        
        if (newSubdirectory != nil) {
            deletePath += newSubdirectory!
            var dir:ObjCBool=true
            NSFileManager.defaultManager().fileExistsAtPath(deletePath, isDirectory:&dir)
            if (!dir) {
                return false;
            }
            
            var isDir:ObjCBool=false;
            var exists:Bool = NSFileManager.defaultManager().fileExistsAtPath(deletePath, isDirectory:&isDir)
            if (exists == false) {
                /* a file of the same name exists, we don't care about this so won't do anything */
                if !isDir {
                    /* subdirectory already exists, don't create it again */
                    return false;
                }
            }
        }
        
        
        
        // Delete the file and see if it was successful
        var error:NSError?
        var ok:Bool = NSFileManager.defaultManager().removeItemAtPath(deletePath, error: &error)
        
        if (error != nil) {
            println(error)
        }
        // Return status of file save
        return ok;
        
    }
    
    class func loadData(path:String, subdirectory:String) -> String {
        
        var newPath = self.stripSlashIfNeeded(path)
        var newSubdirectory:String? = self.stripSlashIfNeeded(subdirectory)
        
        // Create generic beginning to file save path
        var loadPath = self.applicationDirectory().path!+"/"
        
        if (newSubdirectory != nil) {
            loadPath += newSubdirectory!
//            self.createSubDirectory(loadPath)
            loadPath += "/"
        }
        
        // Add requested save path
        loadPath += newPath
        var error:NSError?
        println(loadPath)
        // Save the file and see if it was successful
    
        var text:String? = String(contentsOfFile:loadPath, encoding:NSUTF8StringEncoding, error: &error)
        
        // Return status of file save
        if !(text != nil) {
            text = ""
        }
        return text!
        
    }
    
    class func saveData(fileString:String, path:String, subdirectory:String) -> Bool {
        
        var newPath = self.stripSlashIfNeeded(path)
        
        
        // Create generic beginning to file save path
        var savePath = self.applicationDirectory().path!+"/"
        
        if (subdirectory != "") {
        var newSubdirectory:String? = self.stripSlashIfNeeded(subdirectory)
            if (newSubdirectory != nil) {
                savePath += newSubdirectory!
                self.createSubDirectory(savePath)
                savePath += "/"
            }
        }
        
        // Add requested save path
        savePath += path
        println(savePath)
        var error:NSError?;
        // Save the file and see if it was successful
//        var ok:Bool = fileString.writeToFile(savePath, atomically:false, encoding:NSUTF8StringEncoding, error:&error)
        var ok : Bool
        let data = fileString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        if NSFileManager.defaultManager().fileExistsAtPath(savePath) {
            var err:NSError?
            if let fileHandle = NSFileHandle(forWritingAtPath: savePath) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
                ok = true
            }
            else {
                println("Can't open fileHandle \(err)")
                ok = false
            }
        }
        else {
            var err:NSError?
            ok = fileString.writeToFile(savePath, atomically:false, encoding:NSUTF8StringEncoding, error:&error)
//            if !data.writeToURL(fileurl, options: .DataWritingAtomic, error: &err) {
//                println("Can't write \(err)")
//            }
        }
        
        if (error != nil) {
            println(error)
        }
        
        // Return status of file save
        return ok;
    }
    
    class func applicationDirectory() -> NSURL {
        
//        var directory:String? = NSTemporaryDirectory();
        
        /*
        Put app-created support files in the Library/Application support/ directory. In general, this directory includes files that the app uses to run but that should remain hidden from the user. This directory can also include data files, configuration files, templates and modified versions of resources loaded from the app bundle.
        */
        var directory:String?
        var paths:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true); //save data to Document directory so we can view it by using iTunes. Need to add key UIFileSharingEnabled = TRUE to Info.plist
//        var paths:[AnyObject] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true);
        if paths.count > 0 {
            if let pathString = paths[0] as? NSString {
                directory = pathString as String
            }
        }
        
        return NSURL(fileURLWithPath: directory!)!
        
    }
    
    class func stripSlashIfNeeded(stringWithPossibleSlash:String) -> String {
        var stringWithoutSlash:String = stringWithPossibleSlash
        // If the file name contains a slash at the beginning then we remove so that we don't end up with two
        if stringWithPossibleSlash.hasPrefix("/") {
            stringWithoutSlash = stringWithPossibleSlash.substringFromIndex(advance(stringWithoutSlash.startIndex,1))
        }
        // Return the string with no slash at the beginning
        return stringWithoutSlash
    }
    
    class func createSubDirectory(subdirectoryPath:NSString) -> Bool {
        var error:NSError?
        var isDir:ObjCBool=false;
        var exists:Bool = NSFileManager.defaultManager().fileExistsAtPath(subdirectoryPath as String, isDirectory:&isDir)
        if (exists) {
            /* a file of the same name exists, we don't care about this so won't do anything */
            if isDir {
                /* subdirectory already exists, don't create it again */
                return true;
            }
        }
        var success:Bool = NSFileManager.defaultManager().createDirectoryAtPath(subdirectoryPath as String, withIntermediateDirectories:true, attributes:nil, error:&error)
        
        if (error != nil) { println(error) }
        
        return success;
    }
    
    class func createSentDirectory() {
        self.createSubDirectory(self.applicationDirectory().path! + "/sent")
    }
    
    class func getSentDirectory() -> String {
        return self.applicationDirectory().path! + "/sent"
    }
    
    class func isSent(dataOfDate: String) -> Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(dataOfDate)
    }
}
