//
//  LoginViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/8/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//
//  This is the login view to spotify

import UIKit
import WebKit

class LoginViewController: UIViewController, SPTStoreControllerDelegate, WebViewControllerDelegate{
    
    var authViewController: UIViewController?
    var firstLoad: Bool!
    
    //  login button
    @IBOutlet var loginButtonOutlet: UIButton!
    
    @IBAction func loginButtonS(_ sender: UIButton) {
        self.openLoginPage()
    }
    
    func openLoginPage() {
        let auth = SPTAuth.defaultInstance()
        // Check if "flip-flop" application authentication is supported.
        if SPTAuth.supportsApplicationAuthentication() {
            print("flip flop supported")
            UIApplication.shared.open(auth!.spotifyAppAuthenticationURL(), options: [:], completionHandler: nil)
        } else {
            print("flip flop NOT supported")
            self.authViewController = self.getAuthViewController(withURL: SPTAuth.defaultInstance().spotifyWebAuthenticationURL())
            self.definesPresentationContext = true
            self.present(self.authViewController!, animated: true, completion: { _ in })
        }
    }
    
    func getAuthViewController(withURL url: URL) -> UIViewController {
        let webView = WebViewController(url: url)
        webView.delegate = self
        
        return UINavigationController(rootViewController: webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.sessionUpdatedNotification), name: NSNotification.Name(rawValue: "sessionUpdated"), object: nil)
        self.firstLoad = true
        
        // The login button gets rounded like a potify button
        loginButtonOutlet.layer.cornerRadius = 20
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let auth = SPTAuth.defaultInstance()
        // Uncomment to turn off native/SSO/flip-flop login flow
        //auth.allowNativeLogin = NO;
        // Check if we have a token at all
        if auth!.session == nil {
            //self.statusLabel.text = ""
            return
        }
        // Check if it's still valid
        if auth!.session.isValid() && self.firstLoad {
            // It's still valid, show the player.
            self.showPlayer()
            return
        }
        // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
        //self.statusLabel.text = "Token expired."
        if auth!.hasTokenRefreshService {
            self.renewTokenAndShowPlayer()
            return
        }
        // Else, just show login dialog
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func sessionUpdatedNotification(_ notification: Notification) {
        let auth = SPTAuth.defaultInstance()
        self.presentedViewController?.dismiss(animated: true, completion: { _ in })
        if auth!.session != nil && auth!.session.isValid() {
            self.showPlayer()
        }
        else {
            print("*** Failed to log in")
        }
    }
    
    func showPlayer() {
        self.firstLoad = false
        self.performSegue(withIdentifier: "ShowPlayer", sender: nil)
    }
    
    internal func productViewControllerDidFinish(_ viewController: SPTStoreViewController) {
        //self.statusLabel.text = "App Store Dismissed."
        viewController.dismiss(animated: true, completion: { _ in })
    }

    func renewTokenAndShowPlayer() {
        SPTAuth.defaultInstance().renewSession(SPTAuth.defaultInstance().session) { error, session in
            SPTAuth.defaultInstance().session = session
            if error != nil {
                print("*** Error renewing session: \(error)")
                return
            }
            self.showPlayer()
        }
    }
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
        // User tapped the close button. Treat as auth error
    }

}
