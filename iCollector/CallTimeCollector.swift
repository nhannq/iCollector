//
//  CallTimeCollector.swift
//  iCollector
//
//  Created by Nhan Nguyen on 4/15/15.
//  Copyright (c) 2015 University of Connecticut. All rights reserved.
//

import Foundation
import CoreTelephony


class CallTimeCollector: NSObject {
    
    
    func monitorCallTime() {
        var callCenter = CTCallCenter()
        callCenter.callEventHandler = { (call:CTCall!) in
            
            switch call.callState {
            case CTCallStateConnected:
                println("CTCallStateConnected")
//                self.callConnected()
            case CTCallStateDisconnected:
                println("CTCallStateDisconnected")
//                self.callDisconnected()
            case CTCallStateDialing:
                println("Dialing")
            case CTCallStateIncoming:
                println("Incoming")
            default:
                //Not concerned with CTCallStateDialing or CTCallStateIncoming
                break
            }
        }
    }
    
    func callConnected(){
        println("Receive the call")
        // Do something when call connects
    }
    
    func callDisconnected() {
        // Do something when call disconnects
    }
}