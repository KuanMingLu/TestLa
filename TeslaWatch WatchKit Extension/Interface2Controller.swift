//
//  Interface2Controller.swift
//  TeslaWatch WatchKit Extension
//
//  Created by Kuan Lu on 2022/5/31.
//

import WatchKit
import Foundation


class Interface2Controller: WKInterfaceController {
    var currentVehicleId:Int?
    var currentVehicleData = [String:Any]() {
        didSet {
            
        }
    }
    
    @IBOutlet weak var AirconSwitch: WKInterfaceSwitch!
    
    @IBOutlet weak var FrontDoorSwitch: WKInterfaceSwitch!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
