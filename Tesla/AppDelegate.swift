//
//  AppDelegate.swift
//  Tesla
//
//  Created by Kuan Lu on 2021/9/21.
//

import UIKit

import WatchConnectivity
import Combine
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var commandAnyCancellable:AnyCancellable?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let notificationCenter = NotificationCenter.default
        let publisher = notificationCenter.publisher(for: CommandManager.CommandNotificationName,object: CommandManager.shared)
//        self.commandAnyCancellable = publisher.sink(receiveValue: { notification in
//            guard let userInfo = notification.userInfo,let commandId = userInfo[MessageAttribute.commandId] as? CommandType,let message = userInfo[MessageAttribute.message] as? [String:Any] else {
//                return
//            }
//
//
//            if commandId == .requestToken {
//                ....
//            }
//
//        })
//
        self.commandAnyCancellable = publisher.compactMap({ (notification) -> (CommandType,[String:Any])? in
            //
            guard let userInfo = notification.userInfo,let commandId = userInfo[MessageAttribute.commandId] as? CommandType,let message = userInfo[MessageAttribute.message] as? [String:Any] else {
                return nil
            }
            return (commandId,message)
        
        }).sink(receiveValue: { (commandId,message) in
            
            switch commandId {
            case .requestToken:
                if let token = APIManager.shared.token.token {
                    CommandManager.shared.sendMessage(.sendToken, message: ["token":token])
                }
            case .sendToken:
                break
            }
        })
    
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate:WCSessionDelegate
{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("\(activationState.rawValue)  Error:\(error)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("session inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("session deactive")
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Message:\(message)")
        CommandManager.shared.handle(message)
    }
}
