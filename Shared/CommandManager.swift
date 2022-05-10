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
    case message = "message"
}

class CommandManager :NSObject {
    static let shared = CommandManager()
    static let CommandNotificationName = Notification.Name(rawValue: "WCReceiveCommand")
    func requestToken() {
        
    }
    func sendMessage(_ commandType:CommandType,message:[String:Any] = [String:Any]()) {
        WCSession.default.sendMessage([MessageAttribute.commandId.rawValue:commandType.rawValue,
                                       MessageAttribute.message.rawValue:message]) { reply in
            //message send
        } errorHandler: { error in
            //message send failed
        }
        
    }
    func handle(_ message:[String:Any]) {
        
        guard let value = message[MessageAttribute.commandId.rawValue] as? Int,let commandId = CommandType(rawValue: value),let messageData = message[MessageAttribute.message.rawValue] as? [String:Any] else {
            return
        }
        NotificationCenter.default.post(name: CommandManager.CommandNotificationName , object: self,userInfo: [MessageAttribute.commandId:commandId,MessageAttribute.message:messageData])
        
    }
    
}
