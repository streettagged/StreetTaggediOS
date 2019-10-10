//
//  PostCell.swift
//  StreetTagged
//
//  Created by John O'Sullivan on 9/15/19.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

protocol PostCellDelegate {
    func sharePost(_ image: UIImage)
    func likePost(_ post: Post)
}

class PostCell: BaseCollectionViewCell {
    let cellID = "PostCellPhotoCell"
    
    var delegate: PostCellDelegate?
    //let currentUser = UserDefaults.standard.object(forKey: "uid") as! String
    let currentUser = ""
    
    let profileSize: CGFloat = 40.0
    var post: Post? {
        didSet {
            loadCell(post!)
        }
    }
    
    var isPostLiked = false
    var isPostBookmarked = false
    var stackHeight: NSLayoutConstraint?
    
    var artLocation: CLLocation?
    
    lazy var userProfile: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = profileSize/2
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    var additionalImages: [String] = []
    
    
    lazy var imageView: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        let collections = UICollectionView(frame: .zero, collectionViewLayout: flow)
        collections.showsHorizontalScrollIndicator = false
        collections.register(PhotoCell.self, forCellWithReuseIdentifier: cellID)
        collections.delegate = self
        collections.dataSource = self
        collections.isPagingEnabled = true
        collections.backgroundColor = .white
        return collections
    }()
    
    lazy var page: UIPageControl = {
        let page = UIPageControl()
        page.currentPageIndicatorTintColor = .blueInstagram
        page.pageIndicatorTintColor =  UIColor.lightGray.withAlphaComponent(0.57)
        page.hidesForSinglePage = true
        return page
    }()
    
    lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(likePost), for: .touchUpInside)
        return button
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(showComments), for: .touchUpInside)
        return button
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sharePost), for: .touchUpInside)
        return button
    }()
    
    lazy var buttonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [likeButton])
        stack.distribution = .equalSpacing
        stack.axis = .vertical
        stack.alignment = .leading
        //stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let postText: UILabel = {
        let text = UILabel()
        text.numberOfLines = 0
        return text
    }()
    
    lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [page])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    fileprivate func setupProfile() {
        addSubview(userProfile)
        userProfile.heightAnchor.constraint(equalToConstant: profileSize).isActive = true
        userProfile.widthAnchor.constraint(equalToConstant: profileSize).isActive = true
        userProfile.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        userProfile.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
    }
    
    fileprivate func setupPostImage() {
        addSubview(imageView)
        addConstraintsWithFormat(format: "H:|[v0]|", views: imageView)
        imageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        //imageView.topAnchor.constraint(equalTo: userProfile.bottomAnchor, constant: 6).isActive = true
    }
    
    fileprivate func setupHeader() {
        addSubview(usernameLabel)
        usernameLabel.leftAnchor.constraint(equalTo: userProfile.rightAnchor, constant: 6).isActive = true
        usernameLabel.widthAnchor.constraint(equalToConstant: 120).isActive = true
        usernameLabel.centerYAnchor.constraint(equalTo: userProfile.centerYAnchor).isActive = true
    }
    
    fileprivate func setupButtons() {
        //Add Like Comment Share
        addSubview(buttonsStack)
        buttonsStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 4).isActive = true
        buttonsStack.widthAnchor.constraint(equalToConstant: 120).isActive = true
        buttonsStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
        buttonsStack.topAnchor.constraint(equalTo: stack.bottomAnchor).isActive = true
        //Add Bookmark
        addSubview(shareButton)
        shareButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        shareButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        shareButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        shareButton.topAnchor.constraint(equalTo: stack.bottomAnchor).isActive = true
    }
    
    fileprivate func setupPostText() {
        addSubview(postText)
        addConstraintsWithFormat(format: "H:|-8-[v0]-8-|", views: postText)
        postText.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor).isActive = true
    }
    
    fileprivate func setupPageControll() {
        addSubview(stack)
        center_X(item: stack)
        stack.topAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        stackHeight = stack.heightAnchor.constraint(equalToConstant: 10)
        stackHeight?.isActive = true
    }
    
    override func setup() {
        backgroundColor = .white
        //setupProfile()
        setupPostImage()
        //setupHeader()
        setupPageControll()
        setupButtons()
        setupPostText()
    }
    
    fileprivate func loadCell(_ post: Post) {
        //userProfile.loadImage(post.profile)
        additionalImages = []
        //self.backgroundColor = UIColor.red
        
        self.artLocation = CLLocation.init(latitude: CLLocationDegrees.init(post.coordinates[1]), longitude: CLLocationDegrees.init(post.coordinates[0]))
        
        post.additionalImages.forEach { (_, val) in
            additionalImages.append(val)
        }
        imageView.reloadData()
        page.numberOfPages = post.additionalImages.count + 1
        if additionalImages.count == 0 {
            stackHeight?.constant = 0
        } else {
            stackHeight?.constant = 12
        }
        if imageView.visibleCells.count > 0 {
            if let cell = imageView.visibleCells[0] as? PhotoCell {
                page.currentPage = cell.index ?? 0
            }
        }
        usernameLabel.text = post.username
        let postAttributedText = NSMutableAttributedString(string: post.username + " ", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        postAttributedText.append(NSAttributedString(string: post.about , attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        postAttributedText.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10)]))
        postAttributedText.append(NSAttributedString(string: getTimeElapsed(post.created), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: UIColor.gray]))
        
        postAttributedText.append(NSAttributedString(string: getDistanceFromGlobalLocation(artLocation: self.artLocation!), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13), NSAttributedString.Key.foregroundColor: UIColor.gray]))
        
        postText.attributedText = postAttributedText
        if  post.likes {
            likeButton.setImage(#imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.tintColor = .red
            isPostLiked = true
        } else {
            likeButton.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysTemplate), for: .normal)
            likeButton.tintColor = .black
            isPostLiked = false
        }
    }
    
    @objc func showComments() {
        
    }
    
    @objc func likePost() {
        if (userGlobalState == .userSignedIn) {
            if let post = post {
                if isPostLiked {
                    likeButton.setImage(#imageLiteral(resourceName: "like_unselected").withRenderingMode(.alwaysTemplate), for: .normal)
                    likeButton.tintColor = .black
                    post.likes = false
                } else {
                    likeButton.setImage(#imageLiteral(resourceName: "like_selected").withRenderingMode(.alwaysTemplate), for: .normal)
                    likeButton.tintColor = .red
                    post.likes = true
                }
                isPostLiked = !isPostLiked
            }
            delegate?.likePost(post!)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: GLOBAL_NEED_SIGN_UP), object: nil)
        }
    }
    
    @objc func likeGesture() {
        if !isPostLiked {
                    likePost()
                    let heartIcon: UIImageView = {
                        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
                        image.image = #imageLiteral(resourceName: "red-heart").withRenderingMode(.alwaysOriginal)
                        image.contentMode = .scaleAspectFit
                        return image
                    }()
                    heartIcon.center = imageView.center
                    addSubview(heartIcon)
                    heartIcon.layer.transform = CATransform3DMakeScale(0, 0, 0)
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                        heartIcon.layer.transform = CATransform3DMakeScale(1, 1, 1)
                    }) { (_) in
                        UIView.animate(withDuration: 0.5, delay: 0.75, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                            heartIcon.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1)
                            heartIcon.alpha = 0
                        }, completion: { (_) in
                            heartIcon.removeFromSuperview()
                        })
                    }
                }
    }
    
    @objc func sharePost() {
        if let image = imageView.visibleCells[0] as? PhotoCell {
            delegate?.sharePost(image.imageView.image!)
        }
    }
    
    @objc func bookmarkPost() {
        if let post = post {
            if isPostBookmarked {
                
                post.bookmarks[currentUser] = nil
            } else {
                
                post.bookmarks[currentUser] = 1
            }
            isPostBookmarked = !isPostBookmarked
        }
    }
}

extension PostCell: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let _ = post {
            return additionalImages.count + 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! PhotoCell
        if let post = post {
            if indexPath.item == 0 {
                cell.imageView.loadImage(post.image)
            } else {
                cell.imageView.loadImage(additionalImages[indexPath.item - 1])
            }
        }
        let gesture = UITapGestureRecognizer(target: self, action: #selector(likeGesture))
        gesture.numberOfTapsRequired = 2
        cell.imageView.addGestureRecognizer(gesture)
        cell.imageView.isUserInteractionEnabled = true
        cell.index = indexPath.item
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = targetContentOffset.pointee.x
        page.currentPage = Int(x / frame.width)
        
    }
}
