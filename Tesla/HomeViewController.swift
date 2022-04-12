//
//  HomeViewController.swift
//  Tesla
//
//  Created by Kuan Lu on 2021/10/14.
//

import UIKit
import IPaAVPlayer
import AVFoundation
import MapKit
import Contacts
class HomeViewController: UIViewController {
    let updateStatusTime:TimeInterval = 6
    @IBOutlet weak var insideTempLabel: UILabel!
    @IBOutlet weak var ousideTempLabel: UILabel!
    @IBOutlet weak var batteryInfoLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var speedNameLabel: UILabel!
    @IBOutlet weak var gpsLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var lockedSwitch: ScrollSwitch!
    @IBOutlet weak var climateSwitch: ScrollSwitch!
    @IBOutlet weak var powerSwitch: ScrollSwitch!
    @IBOutlet weak var rtSwitch: ScrollSwitch!
    var currentVehicleId:Int?
    var currentVehicleData = [String:Any]()
    var updateStatusTimer:Timer?
    var lastUpdateTime:TimeInterval = 0
    var lastUpdateLabelTimer:Timer?
    var videoView:IPaAVPlayerView {
        return self.view as! IPaAVPlayerView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "bg", withExtension: "mov") {
            let player = IPaAVPlayer()
            player.setPlayingUrl(url)
            player.isLoop = true
            self.videoView.avPlayer = player
            self.videoView.videoGravity = .resizeAspectFill
            player.play()
            
            
        }
        self.lockedSwitch.delegate = self
        self.rtSwitch.delegate = self
        self.climateSwitch.delegate = self
        self.powerSwitch.delegate = self
        batteryInfoLabel.text = "-"
        self.ousideTempLabel.text = "室外 -"
        self.insideTempLabel.text = "車內 -"
        
        
        self.speedLabel.text = "- km"
        self.speedNameLabel.text = "停車"
        self.gpsLabel.text = ""
        self.lastUpdateTime = Date().timeIntervalSince1970
        self.lastUpdateLabelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
            let currentTime = Date().timeIntervalSince1970
            self.lastUpdateLabel.text = "\(currentTime - self.lastUpdateTime)"
        })
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
        
        // Do any additional setup after loading the view.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    func reloadCurrentState() {
        guard let currentVehicleId = currentVehicleId else {
            return
        }
        APIManager.shared.apiGetVehicleData(currentVehicleId) { vehicleData in
            
            self.currentVehicleData = vehicleData
            //get charge state
            
            let chargeState = vehicleData["charge_state"] as? [String:Any] ?? [String:Any]()
            if let chargingState = chargeState["charging_state"] as? String,chargingState == "Charging" {
                //charging
                var time_to_full_charge = chargeState["time_to_full_charge"] as? Double ?? 0
                let hours = Int(time_to_full_charge)
                let totalMinutes = Int(time_to_full_charge * 60)
                let minutes = totalMinutes % 60
                
                if hours < 1 {
                    self.batteryInfoLabel.text = "\(minutes)分鐘"
                }
                else {
                    self.batteryInfoLabel.text = "\(hours)小時 \(minutes)分鐘"
                }
            }
            else {
                let batteryLevel:Int = chargeState["battery_level"] as? Int ?? 0
                let batteryRange:Double = chargeState["battery_range"] as? Double ?? 0
                
                let measurement = Measurement(value: batteryRange, unit: UnitLength.miles)
                let formatter = MeasurementFormatter()
                formatter.locale = Locale.current
                formatter.numberFormatter.minimumFractionDigits = 0
                formatter.numberFormatter.maximumFractionDigits = 0
                
                let rangeString = formatter.string(from: measurement)
                self.batteryInfoLabel.text = "⚡️\(batteryLevel)%    \(rangeString)"
                
                
            }
            
            
            
            //get tempature
            let climate_state = vehicleData["climate_state"] as? [String:Any] ?? [String:Any]()
            let outsideTemp = climate_state ["outside_temp"] as? Double ?? 0
            let insideTemp = climate_state["inside_temp"] as? Double ?? 0
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 0
            let formatter = MeasurementFormatter()
            formatter.numberFormatter = numberFormatter
            
            let outsideTempMeasurement = Measurement(value: outsideTemp, unit: UnitTemperature.celsius)
            let insideeTempMeasurement = Measurement(value: insideTemp, unit: UnitTemperature.celsius)
            
            self.ousideTempLabel.text = "室外 \(formatter.string(from: outsideTempMeasurement))"
            self.insideTempLabel.text = "車內 \(formatter.string(from: insideeTempMeasurement))"
            
            
            let drive_state = vehicleData["drive_state"] as? [String:Any] ?? [String:Any]()
            let speed = drive_state["speed"] as? Double ?? 0
            //                if speed > 0 {
            //                    self.speedNameLabel.text = "行駛中"
            //                }
            //                else {
            //                    self.speedNameLabel.text = "停車"
            //
            //                }
            self.speedNameLabel.text = speed > 0  ? "行駛中" : "停車"
            var speedMeasure = Measurement(value: speed, unit: UnitSpeed.milesPerHour)
            speedMeasure.convert(to: .kilometersPerHour)
            self.speedLabel.text = "\(formatter.numberFormatter.string(from: NSNumber(value: speedMeasure.value)) ?? "-") km"
            
            if let latitude = drive_state["latitude"] as? Double , let longitude = drive_state["longitude"] as? Double {
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: latitude, longitude: longitude)
                
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let _ = error {
                        return
                    }
                    guard let placemarks = placemarks,let placemark = placemarks.first else {
                        return
                    }
                    self.gpsLabel.text = placemark.name
                }
            }
            let vehicle_state = vehicleData["vehicle_state"] as? [String:Any] ?? [String:Any]()
             let locked:Bool = vehicle_state["locked"] as? Bool ?? false
            self.lockedSwitch.isOn = !locked
            
            let is_climate_on = climate_state ["is_climate_on"] as? Bool ?? false
            self.climateSwitch.isOn = is_climate_on
            
            
            let power = drive_state["power"] as? Int ?? 0
            self.powerSwitch.isOn = power != 0
            
            let rt = vehicle_state["rt"] as? Int ?? 0
            self.rtSwitch.isOn = rt != 0
            
            self.lastUpdateTime = Date().timeIntervalSince1970
        }
        
    }
}

extension HomeViewController: ScrollSwitchDelegate {
    func onIsOnUpdate(_ sender: ScrollSwitch) {
        guard let vehicleId = self.currentVehicleId else {
            return
        }
        if sender == self.powerSwitch {
            if sender.isOn {
                //power on
                APIManager.shared.apiWakeup(vehicleId) { success in
                    if !success {
                        self.powerSwitch.isOn = false
                    }
                }
                
            }
            else {
                if let drive_state = self.currentVehicleData["drive_state"] as? [String:Any],let power = drive_state["power"] as? Int, power != 0 {
                    self.powerSwitch.isOn = true
                }
                
            }
        }
        else if sender == self.lockedSwitch {
            if sender.isOn {
                //unlock door
                APIManager.shared.apiMakeCommand(vehicleId,command:.unlockDoor) { success in
                    
                    if !success {
                        self.lockedSwitch.isOn = false
                    }
                }
                
            }
            else {
                //lock door
                APIManager.shared.apiMakeCommand(vehicleId,command:.lockDoor) { success in
                    if !success {
                        self.lockedSwitch.isOn = true
                    }
                }
            }
            
            
        }
        else if sender == self.rtSwitch {
            APIManager.shared.apiMakeCommand(vehicleId,command:.actuateTrunk,parameters: ["which_trunks":"rear"]) { success in
                if !success {
                    let rt = self.currentVehicleData["rt"] as? Int ?? 0
                    self.rtSwitch.isOn = rt != 0
                }
                
            }
            
            
        }
        else if sender == self.climateSwitch {
            if sender.isOn{
                APIManager.shared.apiMakeCommand(vehicleId, command: .climateOn) { success in
                    if !success {
                        self.climateSwitch.isOn = false
                    }
                }
            }
            else {
                APIManager.shared.apiMakeCommand(vehicleId, command: .climateOff) { success in
                    if !success {
                        self.climateSwitch.isOn = true
                    }
                }
            }
        }
    }
}
