//
//  FeedController.swift
//  StreetTagged
//
//  Created by John O'Sullivan on 9/13/19.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import UIKit
import Foundation
import AWSMobileClient
import Alamofire
import AppleWelcomeScreen
import CoreLocation
import MapKit
import Lightbox
import SPPermissions

class FeedController: UICollectionViewController {
    let cellIDEmpty = "EmptyPostCell"
    let cellID = "postCell"
    
    var isRefreshingPosts: Bool = false
    var isShowingImage: Bool = false
    
    let tapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapticFeedbackGenerator.prepare()
        
        setup()
        refreshPosts()
        NotificationCenter.default.addObserver(self, selector: #selector(postedNotification), name: NSNotification.Name(rawValue: GLOBAL_POSTS_REFRESHED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(signUpNotification), name: NSNotification.Name(rawValue: GLOBAL_NEED_SIGN_UP), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isFirstLaunch()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    lazy var refresh: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .black
        refresh.addTarget(self, action: #selector(refreshAction), for: .allEvents)
        return refresh
    }()
    
    
    let titleView: UIImageView = {
        let view = UIImageView()
        //view.image = #imageLiteral(resourceName: "logo2").withRenderingMode(.alwaysOriginal)
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    fileprivate func setup() {
        view.backgroundColor = .white
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: cellID)
        navigationItem.titleView = titleView
        collectionView.refreshControl = refresh
        let filterItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filter))
        navigationItem.rightBarButtonItem = filterItem
    }
    
    @objc func filter() {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count == 0 ? 0 : posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if posts.count == 0 {
            
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! PostCell
        cell.delegate = self
        if indexPath.item >= posts.count { return cell }
        cell.simplePost = globalSimpleMode
        cell.post = posts[indexPath.item]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
         if (indexPath.row == posts.count - 1) {
            if (!isRefreshingPosts) {
                isRefreshingPosts = true
                pageGetMorePosts()
            }
         }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                   didEndDisplaying cell: UICollectionViewCell,
                     forItemAt indexPath: IndexPath) {
      cell.prepareForReuse()
    }
    
    @objc fileprivate func refreshAction() {
        topRefreshPost()
    }
    
    @objc func shareButtonPressed() {

    }
    
    @objc func postedNotification() {
        self.refresh.endRefreshing()
        self.collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            self.isRefreshingPosts = false
        }
    }
    
    @objc func signUpNotification() {
        let alert = UIAlertController(title: "Are you logged in?", message: "Please sign in or create an account to favorite street art as well as submit art.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Sign In/Sign Up", style: UIAlertAction.Style.default, handler: { (alert: UIAlertAction!) in
            userSignIn(navController: self.navigationController!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (alert: UIAlertAction!) in
            
        }))
        self.navigationController!.present(alert, animated: true, completion: nil)
    }
    
    func isFirstLaunch() {
        if (UserDefaults.isFirstLaunch()) {
            var configuration = AWSConfigOptions()
            
            configuration.appName = "Street Tagged"
            configuration.appDescription = "Street Tagged is the easiest and most enjoyable way to find and share your favorite street art."
            configuration.tintColor = UIColor.gray

            var item1 = AWSItem()
            item1.image = UIImage(named: "photo_big-1")
            item1.title = "Capture local street art"
            item1.description = "Post murals, post ups, and grafitti to share with the world."

            var item2 = AWSItem()
            item2.image = UIImage(named: "find_1")
            item2.title = "Discover new favorites"
            item2.description = "Get push notifications when you are near popular art at home or while on the road."

            var item3 = AWSItem()
            item3.image = UIImage(named: "me_1")
            item3.title = "Subscribe to your favorite artists."
            item3.description = "Get information and updates direct from the street artists."

            configuration.items = [item1, item2, item3]

            configuration.continueButtonAction = {
                self.dismiss(animated: true)
                let controller = SPPermissions.list([.camera, .notification, .locationWhenInUse, .photoLibrary])
                controller.dataSource = self
                controller.delegate = self
                controller.present(on: self)
            }

            let vc = AWSViewController()
            vc.configuration = configuration
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }  else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: GLOBAL_START_LOCATION_MANAGER), object: nil)
        }
    }
}

extension FeedController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if posts.count == 0 {
            let height = view.frame.height - (tabBarController?.tabBar.frame.height ?? 0) - (navigationController?.navigationBar.frame.height ?? 0) - UIApplication.shared.statusBarFrame.height
            return CGSize(width: view.frame.width, height: height)
        } else {
            if indexPath.item >= posts.count { return CGSize.zero}
            let textHeight = heightForView(post: posts[indexPath.item], width: view.frame.width - 16)
            var height: CGFloat = view.frame.width + 106 + textHeight + 5
            
             if posts[indexPath.item].additionalImages.count > 0 {
                height += 10
            }
            
            var heightFinal: CGFloat = height - 40
            if (globalSimpleMode) {
                heightFinal = heightFinal - 110
            }
            
            return CGSize(width: view.frame.width, height: heightFinal)
        }
    }
}

extension FeedController: PostCellDelegate {
    
     
    func likePost(_ post: Post) {
        if (post.likes) {
            favoriteStreetPost(artId: post.id)
        } else {
            favoriteStreetRemove(artId: post.id)
        }
    }
    
    func viewPost(_ image: UIImage, _ post: Post) {
        if (!isShowingImage) {
            isShowingImage = true
            
            tapticFeedbackGenerator.impactOccurred()
            
            let images = [
             LightboxImage(
               image: image,
               text: post.about
             ),
            ]

            let controller = LightboxController(images: images)
            controller.pageDelegate = self
            controller.dismissalDelegate = self

            controller.dynamicBackground = true
            controller.modalPresentationStyle = .fullScreen
            
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func sharePost(_ image: UIImage) {
        let shareText = "Share Image"
        let vc = UIActivityViewController(activityItems: [shareText, image], applicationActivities: [])
        present(vc, animated: true, completion: nil)
    }
    
    func directionPost(_ post: Post) {
        let source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: globalLatitude!, longitude: globalLongitude!)))
        source.name = "You"

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees.init(post.coordinates[1]), longitude: CLLocationDegrees.init(post.coordinates[0]))))
        destination.name = "Street Art"

        MKMapItem.openMaps(with: [source, destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func optionPost(_ post: Post, _ image: UIImage) {
        let alert = UIAlertController(title: "What would you like to do?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Get Directions", style: .default, handler: {(action: UIAlertAction) in
            let source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: globalLatitude!, longitude: globalLongitude!)))
            source.name = "You"

            let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees.init(post.coordinates[1]), longitude: CLLocationDegrees.init(post.coordinates[0]))))
            destination.name = "Street Art"

            MKMapItem.openMaps(with: [source, destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }))
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: {(action: UIAlertAction) in
            let shareText = "Share Image"
            let vc = UIActivityViewController(activityItems: [shareText, image], applicationActivities: [])
            
            if let popoverController = vc.popoverPresentationController {
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popoverController.sourceView = self.view
                popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            }

            self.present(vc, animated: true, completion: nil)

        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension FeedController: LightboxControllerPageDelegate {
  func lightboxController(_ controller: LightboxController, didMoveToPage page: Int) { }
}

extension FeedController: LightboxControllerDismissalDelegate {

  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    isShowingImage = false
  }
}

extension FeedController: SPPermissionsDataSource, SPPermissionsDelegate {
    
    /**
     Configure permission cell here.
     You can return permission if want use default values.
     
     - parameter cell: Cell for configure. You can change all data.
     - parameter permission: Configure cell for it permission.
     */
    func configure(_ cell: SPPermissionTableViewCell, for permission: SPPermission) -> SPPermissionTableViewCell {
        
        /*
         // Titles
         cell.permissionTitleLabel.text = "Notifications"
         cell.permissionDescriptionLabel.text = "Remind about payment to your bank"
         cell.button.allowTitle = "Allow"
         cell.button.allowedTitle = "Allowed"
         
         // Colors
         cell.iconView.color = .systemBlue
         cell.button.allowedBackgroundColor = .systemBlue
         cell.button.allowTitleColor = .systemBlue
         
         // If you want set custom image.
         cell.set(UIImage(named: "IMAGE-NAME")!)
         */
        
        return cell
    }
    
    /**
     Call when controller closed.
     
     - parameter ids: Permissions ids, which using this controller.
     */
    func didHide(permissions ids: [Int]) {
        let permissions = ids.map { SPPermission(rawValue: $0)! }
        print("Did hide with permissions: ", permissions.map { $0.name })
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: GLOBAL_START_LOCATION_MANAGER), object: nil)
    }
    
    /**
     Alert if permission denied. For disable alert return `nil`.
     If this method not implement, alert will be show with default titles.
     
     - parameter permission: Denied alert data for this permission.
     */
    func deniedData(for permission: SPPermission) -> SPPermissionDeniedAlertData? {
        if permission == .notification {
            let data = SPPermissionDeniedAlertData()
            data.alertOpenSettingsDeniedPermissionTitle = "Permission denied"
            data.alertOpenSettingsDeniedPermissionDescription = "Please, go to Settings and allow permission."
            data.alertOpenSettingsDeniedPermissionButtonTitle = "Settings"
            data.alertOpenSettingsDeniedPermissionCancelTitle = "Cancel"
            return data
        } else {
            // If returned nil, alert will not show.
            return nil
        }
    }
}
