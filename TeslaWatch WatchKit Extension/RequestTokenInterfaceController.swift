//
//  RequestTokenInterfaceController.swift
//  TeslaWatch WatchKit Extension
//
//  Created by Kuan Lu on 2022/3/29.
//

import WatchKit
import Foundation


class RequestTokenInterfaceController: WKInterfaceController {

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
    @IBAction func onRequestToken() {
        CommandManager.shared.sendMessage(.requestToken)
    }
    
}
