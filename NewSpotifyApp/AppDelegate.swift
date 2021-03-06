//
//  AppDelegate.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/7/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SPTAudioStreamingDelegate {
    
    var window: UIWindow?
    var session: SPTSession?
    var player: SPTAudioStreamingController?
    // The client ID you got from the developer site
    let kClientId = "50bbc411753b4e7cbab430ace0b42fb2"
    // The redirect URL as you entered it at the developer site
    let kCallbackURL = "new-spotify-app://callback"
    //let kTokenSwapURL = "http://localhost:1234/swap"
    //let kTokenRefreshServiceURL = "http://localhost:1234/refresh"
    // Setting the `sessionUserDefaultsKey` enables SPTAuth to automatically store the session object for future use.
    let kSessionUserDefaultsKey = "SpotifySession"
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Color setup
        UITabBar.appearance().tintColor = UIColor(colorLiteralRed: (30/255), green: (215/255), blue: (96/255), alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor(colorLiteralRed: (30/255), green: (215/255), blue: (96/255), alpha: 1.0)
        UISearchBar.appearance().tintColor = UIColor(colorLiteralRed: (30/255), green: (215/255), blue: (96/255), alpha: 1.0)
        
        // Override point for customization after application launch.
        
        // The client ID you got from the developer site
        SPTAuth.defaultInstance().clientID = kClientId
        
        // The redirect URL as you entered it at the developer site
        SPTAuth.defaultInstance().redirectURL = URL(string:kCallbackURL)
        
        //SPTAuth.defaultInstance().tokenSwapURL = URL(string:kTokenSwapURL)
        
        // Set the scopes you need the user to authorize. `SPTAuthStreamingScope` is required for playing audio.
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope]
        
        //SPTAuth.defaultInstance().tokenRefreshURL = URL(string: kTokenRefreshServiceURL)!
        
        // Setting the `sessionUserDefaultsKey` enables SPTAuth to automatically store the session object for future use.
        SPTAuth.defaultInstance().sessionUserDefaultsKey = kSessionUserDefaultsKey
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // Ask SPTAuth if the URL given is a Spotify authentication callback
        
        print("The URL: \(url)")
        
        // If the incoming url is what we expect we handle it
        if SPTAuth.defaultInstance().canHandle(url) {
                SPTAuth.defaultInstance().handleAuthCallback(withTriggeredAuthURL: url) { error, session in
                // This is the callback that'll be triggered when auth is completed (or fails).
                if error != nil {
                    print("*** Auth error: \(error)")
                    return
                }
                else {
                    SPTAuth.defaultInstance().session = session
                }
                NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "sessionUpdated"), object: self)
            }
        }
        return false
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "NewSpotifyApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

