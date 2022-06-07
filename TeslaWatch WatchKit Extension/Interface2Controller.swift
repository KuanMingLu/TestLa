//
//  Interface2Controller.swift
//  TeslaWatch WatchKit Extension
//
//  Created by Kuan Lu on 2022/5/31.
//

import WatchKit
import Foundation
import Combine

class Interface2Controller: WKInterfaceController {
    var currentVehicleId:Int? {
        get {
            return APIManager.shared.currentVehicleId
        }
        set {
            APIManager.shared.currentVehicleId = newValue
        }
    }
    var currentVehicleData:[String:Any] {
        get {
            return APIManager.shared.currentVehicleData
        }
        set {
            APIManager.shared.currentVehicleData = newValue
        }
    }
    var vehicleDataAnyCancellable:AnyCancellable?
    
    @IBOutlet weak var AirconSwitch: WKInterfaceSwitch!
    
    @IBOutlet weak var powerswitch: WKInterfaceSwitch!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        self.vehicleDataAnyCancellable = APIManager.shared.publisher(for: \.currentVehicleData).sink(receiveValue: { vehicleData in
            let climate_state = vehicleData["climate_state"] as? [String:Any] ?? [String:Any]()
            let is_climate_on = climate_state ["is_climate_on"] as? Bool ?? false
            self.AirconSwitch.setOn( is_climate_on)
            
            let drive_state = vehicleData["drive_state"] as? [String:Any] ?? [String:Any]()
            let power = drive_state["power"] as? Int ?? 0
            self.powerswitch.setOn(power != 0)
        })
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func PowerSwitch(_ value: Bool) {
        guard let currentVehicleId = currentVehicleId else {
            return
        }
            if value{
                //power on
                APIManager.shared.apiWakeup(currentVehicleId) { success in
                    if !success {
                        self.powerswitch.setOn(false)
                    }
                }
                
            }
            else {
                if let drive_state = self.currentVehicleData["drive_state"] as? [String:Any],let power = drive_state["power"] as? Int, power != 0 {
                    self.powerswitch.setOn(true)
                }
                
            }
        
        
    }
    @IBAction func AirconSwitch(_ value: Bool) {
        guard let currentVehicleId = currentVehicleId else {
            return
        }

        if value{
            APIManager.shared.apiMakeCommand(currentVehicleId, command: .climateOn) { success in
                if !success {
                    self.AirconSwitch.setOn(false)
                }
            }
        }
        else {
            APIManager.shared.apiMakeCommand(currentVehicleId, command: .climateOff) { success in
                if !success {
                    self.AirconSwitch.setOn(true)
                }
            }
        }
    }
    
}

