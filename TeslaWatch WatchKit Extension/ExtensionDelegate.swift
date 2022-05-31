//
//  ExtensionDelegate.swift
//  TeslaWatch WatchKit Extension
//
//  Created by Kuan Lu on 2021/12/14.
//

import WatchKit
import WatchConnectivity
import Combine
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var commandAnyCancellable:AnyCancellable?
    override init() {
        super.init()
        let notificationCenter = NotificationCenter.default
        let publisher = notificationCenter.publisher(for: CommandManager.CommandNotificationName,object: CommandManager.shared)
        self.commandAnyCancellable = publisher.compactMap({ (notification) -> (CommandType,[String:Any])? in
            //
            guard let userInfo = notification.userInfo,let commandId = userInfo[MessageAttribute.commandId] as? CommandType,let message = userInfo[MessageAttribute.message] as? [String:Any] else {
                return nil
            }
            return (commandId,message)
        
        }).sink(receiveValue: { (commandId,message) in
            
            switch commandId {
            case .requestToken:
                break
            case .sendToken:
                guard let token = message["token"] as? String,token.count > 0 else {
                    break
                }
                APIManager.shared.token.token = token
                WKInterfaceController.reloadRootPageControllers(withNames: ["home"], contexts: nil, orientation: .horizontal, pageIndex: 0)
                
            }
        })
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        
    }
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        
        if !APIManager.shared.isLogin {
            WKInterfaceController.reloadRootPageControllers(withNames: ["requestToken"], contexts: nil, orientation: .horizontal, pageIndex: 0)
        }
        
        
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
extension ExtensionDelegate :WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        if activationState == .activated {
            if !APIManager.shared.isLogin {
                session.sendMessage([MessageAttribute.commandId.rawValue:CommandType.requestToken.rawValue]) { response in
                    print("response:\(response)")
                } errorHandler: { error in
                    print("error:\(error)")
                }

            }
            
            
        }
        
        
        
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        CommandManager.shared.handle(message)
    }
    
}
