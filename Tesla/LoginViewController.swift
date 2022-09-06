//
//  LoginViewController.swift
//  Tesla
//
//  Created by Kuan Lu on 2021/9/21.
//

import UIKit
import WebKit
class LoginViewController: UIViewController {
    @IBOutlet weak var accountTextField: UITextField!
//    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginWebView: WKWebView!
    lazy var loginInfo = APIManager.shared.createLoginInfo()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let loginInfo = loginInfo else {
            return
        }
        let request = URLRequest(url: loginInfo.loginUrl)
        
        loginWebView.load(request)
        loginWebView.navigationDelegate = self
        let window = UIApplication.shared.keyWindow
    }
    
  
    
}
extension LoginViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url,url.absoluteString.hasPrefix("https://auth.tesla.com/void/callback"),let query = url.query {
            
            var result = [String:String]()
            
            let queryList = query.split(separator: "&") //["code=aaa","b=cccc"]
            
            for q in queryList {
                let data = q.split(separator: "=")
                
                guard let key = data.first, let value = data.last else {
                    continue
                }
                result[String(key)] = String(value)
            }
            guard let code = result["code"] ,let code_verifier = loginInfo?.codeVerifier else {
                return .cancel
            }
            
            APIManager.shared.apiGetToken(code, code_verifier:code_verifier ) { success in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "loginComplete", sender: nil)
                }
                
            }
            return .cancel
        }
        
        return .allow
    }
    
    
}
extension LoginViewController :ScrollSwitchDelegate {
    func onIsOnUpdate(_ sender: ScrollSwitch) {
        
    }
}
