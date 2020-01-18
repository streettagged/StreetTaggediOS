//
//  AppDelegate.swift
//  StreetTagged
//
//  Created by John O'Sullivan on 9/12/19.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import UIKit
import CoreData
import ESTabBarController_swift
import AWSMobileClient
import AWSS3
import Photos
import CoreLocation
import GetStream
import GetStreamActivityFeed


var globalLatitude: CLLocationDegrees?
var globalLongitude: CLLocationDegrees?
var globalLocation: CLLocation = CLLocation.init()

var hasGlobalGPS: Bool = false

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    
    var currentViewController: UIViewController?
    let storyboard: UIStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
    let locationManager = CLLocationManager()

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("location manager authorization status changed")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: GLOBAL_POSTS_REFRESHED), object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            globalLatitude = location.coordinate.latitude
            globalLongitude = location.coordinate.longitude
            globalLocation = location
            hasGlobalGPS = true
        }
    }
    
    @objc func timerGPSFunction() {
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        userStateInitialize(enabledLogs: true, responder: self)
                    
        let profile = storyboard.instantiateViewController(withIdentifier: "Profile") as! ProfileController
 let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGNvbnJveSJ9.rSOAY6E4wxjNisPAZsmuodR6rywEfU_w004em4SfL00"
         
         Client.config = .init(apiKey: "2v627n68x39v", appId: "67539",logsEnabled: true)
         Client.shared.setupUser(GetStreamActivityFeed.User(name: "Dave Conroy",
                                                                  id: "dconroy"),
                                                                  token: token) { result in
  
             if let currentUser = try? result.get() {
                 // Load you feeds.
             } else if let error = result.error {
                 print("Authorization error:", error)
             }
             // or
             if GetStream.User.current != nil {
                 
                 //let userFeed = Client.shared.flatFeed(feedSlug: "user")
                 // Create an Activity. You can make own Activity class or struct with custom properties.
                // let activity = Activity(actor: User.current!, verb: "add", object: "picture:10", foreignId: "picture:10")
                 
              //   userFeed?.add(activity) { result in
                 //A result of the adding of the activity.
              //       print(result)
              //   }
               //  let timelineFeed = Client.shared.flatFeed(feedSlug: "timeline")

               // timelineFeed?.follow(toTarget: userFeed!.feedId, activityCopyLimit: 1) { result in
                    //    print(result)
               // }
               
                 // Read timeline and user's post appears in the feed:
               //  timelineFeed?.get(pagination: .limit(10)) { result in
                 //    let response = try! result.get()
                   //  print(response.results)
                // }
                 
                 
                 
                 
             }
  }
        let flow = UICollectionViewFlowLayout()
        //let v1 = FeedController(collectionViewLayout: flow)
        let v1 = StreamViewController()
        let v2 = NearByController()
        let v3 = FavorController()
        let v4 = FavorController()
        let v5 = profile
        
        currentViewController = v1
                
        let tabBarController = ESTabBarController()
        tabBarController.delegate = self
        tabBarController.title = "Irregularity"
        tabBarController.tabBar.shadowImage = UIImage(named: "transparent")
        tabBarController.tabBar.backgroundImage = UIImage(named: "background")
        tabBarController.shouldHijackHandler = {
        tabbarController, viewController, index in
                if index == 2 {
                    return true
                }
                self.currentViewController = viewController

                if index == 0 {
                    tabBarController.title = "Feed"
                }
                if index == 1 {
                    tabBarController.title = "Nearby"
                }
                if index == 3 {
                    if (userGlobalState == .userSignedIn) {
                        tabBarController.title = "Favorites"
                    } else {
                        return true
                    }
                }
                if index == 4 {
                    tabBarController.title = "Me"
                }
                return false
        }
        tabBarController.didHijackHandler = { tabbarController, viewController, index in
                if index == 2 {
                    if (userGlobalState == .userSignedIn) {
                        let alert = UIAlertController(title: "From?", message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
                            self.getImage(fromSourceType: .camera)
                        }))
                        alert.addAction(UIAlertAction(title: "Photo Album", style: .default, handler: {(action: UIAlertAction) in
                            self.getImage(fromSourceType: .photoLibrary)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
                        self.currentViewController!.present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: "Are you logged in?", message: "Please sign in or create an account to submit and favorite street art.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Sign In/Sign Up", style: UIAlertAction.Style.default, handler: { (alert: UIAlertAction!) in
                            userSignIn(navController: self.currentViewController!.navigationController!)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (alert: UIAlertAction!) in
                            
                        }))
                        self.currentViewController!.present(alert, animated: true, completion: nil)
                    }
                }
                if index == 3 {
                    if (userGlobalState == .userSignedIn) {
                    
                    } else {
                        let alert = UIAlertController(title: "Are you logged in?", message: "Please sign in or create an account to submit and favorite street art.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Sign In/Sign Up", style: UIAlertAction.Style.default, handler: { (alert: UIAlertAction!) in
                            userSignIn(navController: self.currentViewController!.navigationController!)
                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (alert: UIAlertAction!) in
                            
                        }))
                        self.currentViewController!.present(alert, animated: true, completion: nil)
                    }
                }
        }
               
        v1.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "Feed", image: UIImage(named: "home"), selectedImage: UIImage(named: "home_1"))
        v2.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "Nearby", image: UIImage(named: "find"), selectedImage: UIImage(named: "find_1"))
        v3.tabBarItem = ESTabBarItem.init(TabContentView(), title: nil, image: UIImage(named: "photo_verybig"), selectedImage: UIImage(named: "photo_verybig"))
        v4.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "Favorites", image: UIImage(named: "favor"), selectedImage: UIImage(named: "favor_1"))
        v5.tabBarItem = ESTabBarItem.init(TabBasicContentView(), title: "Me", image: UIImage(named: "me"), selectedImage: UIImage(named: "me_1"))
               
        tabBarController.viewControllers = [v1, v2, v3, v4, v5]
               
        let navigationController = BasicNavigationController.init(rootViewController: tabBarController)
        tabBarController.title = "Feed"
        
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        NotificationCenter.default.addObserver(self, selector: #selector(startLocationManager), name: NSNotification.Name(rawValue: GLOBAL_START_LOCATION_MANAGER), object: nil)
    
        return true
    }
    
    @objc func startLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    @objc func toggle() {
        globalSimpleMode = !globalSimpleMode
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: GLOBAL_POSTS_REFRESHED), object: nil)
    }
    
    func getImage(fromSourceType sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = sourceType
            imagePickerController.modalPresentationStyle = .fullScreen
            imagePickerController.allowsEditing = true
            self.currentViewController!.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    @objc func filter() {
        
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        let vc = storyboard.instantiateViewController(withIdentifier: "UploadArt") as! UploadArtController
        vc.image = image
        
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            vc.imageLocation = asset.location
        }           
                
        let navigationController = UINavigationController(rootViewController: vc)
        self.currentViewController!.dismiss(animated: true, completion: nil)
        self.currentViewController!.present(navigationController, animated: true, completion: nil)
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
        let container = NSPersistentContainer(name: "StreetTagged")
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

