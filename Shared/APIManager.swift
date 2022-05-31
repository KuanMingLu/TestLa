//
//  APIManager.swift
//  Tesla
//
//  Created by Kuan Lu on 2021/10/19.
//

import IPaURLResourceUI
import IPaKeyChain
import IPaSecurity
import IPaXMLSection
import libxml2
import IPaLog
import AVFoundation

struct LoginInfo {
    let codeVerifier:String
    let loginUrl:URL
}


class APIManager: NSObject {
    enum ApiCommand:String {
        case lockDoor = "door_lock"
        case unlockDoor = "door_unlock"
        case climateOn = "auto_conditioning_start"
        case climateOff = "auto_conditioning_stop"
        case actuateTrunk = "actuate_trunk"
        
    }
    static let shared = APIManager()
    lazy var resourceUI = IPaURLResourceUI(with: URL(string: "https://owner-api.teslamotors.com")!, delegate: self)
    lazy var authResourceUI = IPaURLResourceUI(with: URL(string: "https://auth.tesla.com/oauth2/v3")!, delegate: nil)
    lazy var token:IPaKeyChainToken = IPaKeyChainToken(self.appServiceName,name:"token",synchronizable: true)
    var appServiceName:String {
        get {
            
            return (Bundle.main.bundleIdentifier ?? "")
        }
    }
    @objc dynamic var isLogin:Bool {
        get {
            return self.token.token != nil
        }
    }

    func createLoginInfo() -> LoginInfo? {
        let length = 86
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code_verifier = String((0..<length).map{ _ in letters.randomElement()! })
        let endPoiint = "https://auth.tesla.com/oauth2/v3/authorize"
        guard let code_challenge = code_verifier.sha256String?.base64UrlString,let url = URL(string: endPoiint) else {
            return nil
        }
        let params = ["client_id":"ownerapi","code_challenge":code_challenge,"code_challenge_method":"S256","redirect_uri":"https://auth.tesla.com/void/callback","response_type":"code","scope":"openid email offline_access","state":"123"]
        
        var apiURLComponent = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        apiURLComponent.queryItems = params.map { (key,value) in
            return URLQueryItem(name: key, value: "\(value)")
        }
        guard let finalUrl = apiURLComponent.url else {
            return nil
        }
        
        return LoginInfo(codeVerifier: code_verifier, loginUrl: finalUrl)
        
        
    }
    func apiGetToken(_ code:String,code_verifier:String,complete:@escaping (Bool)->()) {
        let body = ["grant_type": "authorization_code","client_id": "ownerapi","redirect_uri": "https://auth.tesla.com/void/callback","code":code,"code_verifier":code_verifier]
        
        _ = try? self.authResourceUI.apiUpload("token", method: .post, headerFields: nil, json: body) { result in
            guard let json:[String:Any] = result.jsonData(),let token = json["access_token"] as? String else {
                complete(false)
                return
            }
            _ = try? self.resourceUI.apiUpload("oauth/token", method: .post, headerFields: ["Authorization":"Bearer \(token)"], json: [
                  "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                  "client_id": "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384",
                  "client_secret": "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3"
            ]) { result in
                guard let json:[String:Any] = result.jsonData(),let token = json["access_token"] as? String else {
                    complete(false)
                    return
                }
                self.token.token = token
                complete(true)
            }
            
        }
    }
    func apiVehicles(_ complete:@escaping ([[String:Any]])->()) {
        
        self.resourceUI.apiData("/api/1/vehicles", method: .get, headerFields: nil, params: nil) { result in
            let data:[String:Any] = result.jsonData() ?? [String:Any]()
            let response = data["response"] as? [[String:Any]] ?? [[String:Any]]()
            complete(response)
        }
    }
    func apiGetVehicleData(_ vehicleId:Int,complete:@escaping ([String:Any])->()) {
       
        self.resourceUI.apiData("api/1/vehicles/\(vehicleId)/vehicle_data", method: .get, headerFields: nil, params: nil) { result in
            let data:[String:Any] = result.jsonData() ?? [String:Any]()
            let response = data["response"] as? [String:Any] ?? [String:Any]()
            complete(response)
        }
    }
    
    func apiMakeCommand(_ vehicleId:Int,command:ApiCommand, parameters:[String:Any]? = nil, complete:@escaping (Bool) ->()) {
        self.resourceUI.apiData("api/1/vehicles/\(vehicleId)/command/\(command.rawValue)", method: .post, headerFields: nil, params: parameters) { result in
            let data:[String:Any] = result.jsonData() ?? [String:Any]()
            let result = data["result"] as? Bool ?? false
            complete(result)
        }
    }
    func apiWakeup(_ vehicleId:Int, complete:@escaping (Bool)->()) {
        self.resourceUI.apiData("api/1/vehicles/\(vehicleId)/wake_up", method: .post, headerFields: nil, params: nil) { result in
            let data:[String:Any] = result.jsonData() ?? [String:Any]()
            let result = data["reposnse"] as? [String:Any] ?? [String:Any]()
            if let state = result["state"] as? String,state == "online" {
                complete(true)
            }
            else {
                complete(false)
            }
            
        }
    }
    
}

extension APIManager :IPaURLResourceUIDelegate {
    func sharedHeader(for resourceUI: IPaURLResourceUI) -> [String : String] {
        var headers = [String : String]()
        if let token = self.token.token {
            
            headers["Authorization"] = "Bearer \(token)"
            
        }
        
        
        
        return headers
    }
    
    func handleChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
    
    func handleResponse(_ response: HTTPURLResponse, responseData: Data?) -> Error? {
        return nil
    }
    
  
}
