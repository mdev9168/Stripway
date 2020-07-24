//
//  FeatureCollectionViewCell.swift
//  Stripway
//
//  Created by iOS Dev on 2/7/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit

class FeatureCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var profileImageView: SpinImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    /// The delegate for when we need to do things that we can't do from within the cell
    var delegate: FeatureCollectionViewCellDelegate?
    var index:Int!

    
    /// The post for this cell, does some UI stuff when set
    var post: StripwayPost? {
        didSet {
            updateView()
        }
    }
    
    /// The user for this cell, does some UI stuff when set
    var user: StripwayUser? {
        didSet {
            updateUserInfo()
        }
    }
    
    func updateView() {
        self.layoutIfNeeded()
        self.setPostImage()
    }
    
    /// Setup needed before the cell is fully functional
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileImageView.layer.borderWidth = 1.5
        profileImageView.layer.borderColor = UIColor.white.cgColor
        
        let avatarTapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTap))
        profileImageView.addGestureRecognizer(avatarTapGesture)
        
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTap))
        nameLabel.addGestureRecognizer(usernameTapGesture)
    }
    
    @objc func avatarTap() {
        self.delegate?.segueToProfileFor(self.index)
    }

    /// Called when the user is set, just some UI setup
    func updateUserInfo() {
        self.nameLabel.text = user?.username
        if let photoURLString = user?.profileImageURL {
            profileImageView.showLoading()
            profileImageView.sd_setImage(with: URL(string: photoURLString)) { (outImg, error, type, url) in
                self.profileImageView.hideLoading()
            }
        }        
    }
    
    //Set post image
    func setPostImage() {
        // Could probably just use an aspect ratio constraint and set the constant equal to ratio, but
        // this works and I don't want to break it
        var photoURLString = ""
        
        let ratio = post!.imageAspectRatio
        
        if post?.thumbURL != nil {
            photoURLString = post!.thumbURL!
        }
        else {
            photoURLString = post!.photoURL
        }
        
        postImageView.sd_setImage(with: URL(string: photoURLString)) { (image, error, _, _) in
            guard let image = image else { return }
            let imageRatio = image.size.width / image.size.height
            print("ANDREWTEST: Just double checking the image aspect ratio: \(imageRatio) and this is the cell aspect ratio: \(ratio)")
        }
    }

}

protocol FeatureCollectionViewCellDelegate {
    func segueToProfileFor(_ index: Int)
}

