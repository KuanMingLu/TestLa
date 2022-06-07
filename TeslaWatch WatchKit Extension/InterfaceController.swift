//
//  InterfaceController.swift
//  TeslaWatch WatchKit Extension
//
//  Created by Kuan Lu on 2021/12/14.
//

import WatchKit
import Foundation
import Combine

class InterfaceController: WKInterfaceController {
    let updateStatusTime:TimeInterval = 6
    @IBOutlet weak var lockSwitch: WKInterfaceSwitch!
    @IBOutlet weak var backDoorSwitch: WKInterfaceSwitch!
    var currentVehicleId:Int? {
        get {
            return APIManager.shared.currentVehicleId
        }
        set {
            APIManager.shared.currentVehicleId = newValue
        }
        
        
    }
    var vehicleDataAnyCancellable:AnyCancellable?
    
    
    var currentVehicleData:[String:Any] {
        get {
            return APIManager.shared.currentVehicleData
        }
        set {
            APIManager.shared.currentVehicleData = newValue
        }
    }
    var updateStatusTimer:Timer?
    var lastUpdateTime:TimeInterval = 0
    var lastUpdateLabelTimer:Timer?
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        self.vehicleDataAnyCancellable = APIManager.shared.publisher(for: \.currentVehicleData).sink(receiveValue: { vehicleData in
            
            let vehicle_state = vehicleData["vehicle_state"] as? [String:Any] ?? [String:Any]()
            let locked:Bool = vehicle_state["locked"] as? Bool ?? false
            
            self.lockSwitch.setOn(!locked)
            let rt = vehicle_state["rt"] as? Int ?? 0
            self.backDoorSwitch.setOn(rt != 0)
            
        })
        
        guard let _ = self.currentVehicleId else {
            APIManager.shared.apiVehicles { vehicles in
                guard let data = vehicles.first, let vehicleId = data["id"] as? Int else {
                    //can not get vehicle data
                    return
                }
                self.currentVehicleId = vehicleId
                
                self.reloadCurrentState()
                
                self.updateStatusTimer = Timer.scheduledTimer(withTimeInterval: self.updateStatusTime, repeats: true, block: { timer in
                    self.reloadCurrentState()
                })
            }
            return
        }
        self.reloadCurrentState()
        
        
    }
    func reloadCurrentState() {
        guard let currentVehicleId = currentVehicleId else {
            return
        }
        APIManager.shared.apiGetVehicleData(currentVehicleId) { vehicleData in
            
            self.currentVehicleData = vehicleData
        
           
            
            self.lastUpdateTime = Date().timeIntervalSince1970
        }
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        self.updateStatusTimer?.invalidate()
    }
    
    @IBAction func onLock(_ value: Bool) {
        guard let vehicleId = currentVehicleId else {
            return
        }
        if value {
            //unlock door
            APIManager.shared.apiMakeCommand(vehicleId,command:.unlockDoor) { success in
                
                if !success {
                    self.lockSwitch.setOn(false)
                }
            }
            
        }
        else {
            //lock door
            APIManager.shared.apiMakeCommand(vehicleId,command:.lockDoor) { success in
                if !success {
                    self.lockSwitch.setOn(true)
                }
            }
        }
        
    }
    
    @IBAction func BackDoorSwitch(_ value: Bool) {
    }
    
}
