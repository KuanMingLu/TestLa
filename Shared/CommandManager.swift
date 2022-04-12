//
//  CommandManager.swift
//  Tesla
//
//  Created by Kuan Lu on 2022/3/22.
//

import WatchConnectivity

enum CommandType:Int {
    case requestToken = 0
    case sendToken
}

enum MessageAttribute:String {
    case commandId = "commandId"
}

class CommandManager :NSObject {
    static let shared = CommandManager()
    
    func requestToken() {
        
    }
    func sendMessage(_ commandType:CommandType,message:[String:Any]) {
        
    }
    
}
