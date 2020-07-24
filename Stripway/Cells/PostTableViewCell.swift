//
//  HomeTableViewCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/29/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import FirebaseDatabase
import ReadMoreTextView
import Macaw
import TagListView

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var myScrollView: UIScrollView!
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var viewHashTagContnr: UIView!
    @IBOutlet weak var viewCaptionContner: UIView!
    @IBOutlet weak var textViewCaption: UITextView!
    @IBOutlet weak var tagViewList: TagListView!
    @IBOutlet weak var lblHashText: UILabel!
    @IBOutlet weak var heightConstantOfCaptionText: NSLayoutConstraint!
    @IBOutlet weak var tagView: UIView!

    // Main post information
    @IBOutlet weak var profileImageView: SpinImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var nameLabel_Title: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionTextView: ReadMoreTextView!
    @IBOutlet weak var editableTextView: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    // Buttons and interactive stuff
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var commentImageView: UIImageView!
    @IBOutlet weak var repostImageView: UIImageView!
    @IBOutlet weak var bookmarkImageView: UIImageView!
    @IBOutlet weak var ellipsisButton: UIButton!
    @IBOutlet weak var likesNumberButton: UIButton!
    @IBOutlet weak var commentsNumberButton: UIButton!
    @IBOutlet weak var repostsNumberButton: UIButton!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var infoView: UIView!
    
    /// Whenever the caption height changes, this changes too, so we know where to put the top of the
    /// suggestions container view
    var captionMaxY: CGFloat = 0
    
    var showThumb:Bool = false
    var showingPopUp:Bool = false
    
    var hashTag = ""
    var captionText = ""
    var tagArr = [String]()
    
    var taggedButtons = [UIButton]()
    var taggedVisible = false
    
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
    
    /// The delegate for when we need to do things that we can't do from within the cell
    var delegate: PostTableViewCellDelegate?
    
    /// Setup needed before the cell is fully functional
    override func layoutSubviews() {
        super.layoutSubviews()
        myScrollView.layoutIfNeeded()
        profileImageView.layer.cornerRadius = 20
        
        captionTextView.delegate = self
        editableTextView.delegate = self
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(likeButtonPressed))
        likeImageView.addGestureRecognizer(likeTapGesture)
        
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(commentButtonPressed))
        commentImageView.addGestureRecognizer(commentTapGesture)
        
        let repostTapGesture = UITapGestureRecognizer(target: self, action: #selector(repostButtonPressed))
        repostImageView.addGestureRecognizer(repostTapGesture)
        
        let bookmarkTapGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkButtonPressed))
        bookmarkImageView.addGestureRecognizer(bookmarkTapGesture)
        
        postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showImage)))
        
    }
    
    @IBOutlet weak var postImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImageViewAspectRatioConstraint: NSLayoutConstraint!
    
    
    //set caption
    //var i = 0
    func setTag(){
        self.pageControll.isHidden = false
//        tagViewList.delegate = self
        tagViewList.removeAllTags()
        tagViewList.textFont = UIFont.systemFont(ofSize: 14)
        tagViewList.alignment = .center
        for item in tagArr {
            tagViewList.addTag("#\(item)")
        }
        
        textViewCaption.backgroundColor = .clear
        if self.post?.captionBgColorCode == "#000000" {
            
            textViewCaption.textColor = .white
            viewHashTagContnr.backgroundColor = .black
            viewCaptionContner.backgroundColor = .black
            
            tagViewList.borderColor = .white
            tagViewList.textColor = .white
            lblHashText.textColor = .white
            
        }else {
            textViewCaption.textColor = .black
            viewHashTagContnr.backgroundColor = .white
            viewCaptionContner.backgroundColor = .white
            tagViewList.borderColor = .black
            tagViewList.textColor = .black
            lblHashText.textColor = .black
        }

        textViewCaption.isEditable = false
        textViewCaption.text = captionText
        
        let height = ceil(textViewCaption.contentSize.height) // ceil to avoid decimal
        if height != heightConstantOfCaptionText.constant && viewCaptionContner.frame.height > heightConstantOfCaptionText.constant { // set when height changed
            heightConstantOfCaptionText.constant = height
            textViewCaption.isScrollEnabled = true
            textViewCaption.setContentOffset(CGPoint.zero, animated: false) // scroll to top to avoid "wrong contentOffset" artefact when line count changes
        }

    }
    
    /// Called when the post is set, just some UI setup
    func updateView() {
        hashTag = ""
        captionText = ""
        tagArr.removeAll()
        formatUsernameLabel()
        captionTextView.text = ""//self.post?.caption
        editableTextView.text = self.post?.caption
        editableTextView.isHidden = true
        captionTextView.isHidden = true
        captionTextView.resolveHashtagsAndMentions()
        
        //Rj
        self.viewHashTagContnr.isHidden = true
        self.viewCaptionContner.isHidden = true
        self.pageControll.isHidden = true
        self.viewHashTagContnr.backgroundColor = .clear
        self.viewCaptionContner.backgroundColor = .clear

        if self.post?.caption == "" && self.post?.caption == nil {
            self.myScrollView.contentOffset.x = 0// only image
            self.pageControll.isHidden = true
            print("Image only")
        }else {
            //self.pageControll.isHidden = false
            var trimText = ""
            trimText = self.post?.caption.trimNewLine() ?? ""
            print("After trimmed text -->>\(trimText)")
            let arrObj = trimText.getHasTagPrefixesObjArr()
            if arrObj.count > 0 {
            for text in arrObj{

                if text.prefix == nil {
                    captionText = (captionText) + text.text
                    captionText = captionText + " "
                }else {
                    hashTag = hashTag  + text.text
                    hashTag = hashTag + " "
                    tagArr.append(text.text)
                }
            }
                
            captionText = post!.caption
            tagArr = post!.hashTags

        if captionText != "" && tagArr.count != 0 {
            self.viewHashTagContnr.isHidden = false
            self.viewCaptionContner.isHidden = false
            self.myScrollView.contentOffset.x = SCREEN_WIDTH * 2
            self.pageControll.numberOfPages = 3
            self.pageControll.currentPage = 3
            self.setTag()
        }else if  captionText != "" && tagArr.count == 0 {
            print("caption  found")
            self.myScrollView.contentOffset.x = SCREEN_WIDTH
            self.viewHashTagContnr.isHidden = true
            self.viewCaptionContner.isHidden = false
            self.pageControll.numberOfPages = 2
            self.pageControll.currentPage = 2
            self.setTag()
        }else if  captionText == "" && tagArr.count != 0 {
             print("tag found")
            self.viewHashTagContnr.isHidden = false
            self.viewCaptionContner.isHidden = true
            self.myScrollView.contentOffset.x = SCREEN_WIDTH
            self.pageControll.numberOfPages = 2
            self.pageControll.currentPage = 2
            self.setTag()
        }else {
            self.myScrollView.contentOffset.x = 0
        }
            }else {
                self.myScrollView.contentOffset.x = 0
            }
        }
        
        self.layoutIfNeeded()
        self.setPostImage()
        
        API.Comment.observeCommentCount(forPostID: post!.postID) { (numberOfComments) in
            self.commentsNumberButton.setTitle("\(numberOfComments)", for: .normal)
        }
        
        updateLike(post: post!)
        updateRepost(post: post!)
        updateBookmark(post: post!)
        timestampLabel.baselineAdjustment = .alignCenters
        timestampLabel.text = self.post!.timestamp.convertToTimestamp()
    }
    
//    func updateView() {
//        formatUsernameLabel()
//        captionTextView.text = self.post?.caption
//        editableTextView.text = self.post?.caption
//        captionTextView.resolveHashtagsAndMentions()
//        
////        let newHeight = self.contentView.frame.width / ratio
////        self.postImageViewHeightConstraint.constant = newHeight
////        postImageViewAspectRatioConstraint.constant = ratio
//        self.layoutIfNeeded()
//        self.setPostImage()
//        
//        API.Comment.observeCommentCount(forPostID: post!.postID) { (numberOfComments) in
//            self.commentsNumberButton.setTitle("\(numberOfComments)", for: .normal)
//        }
//        
//        updateLike(post: post!)
//        updateRepost(post: post!)
//        updateBookmark(post: post!)
//        timestampLabel.baselineAdjustment = .alignCenters
//        timestampLabel.text = self.post!.timestamp.convertToTimestamp()
//    }
    
    
    //Set post image
    func setPostImage() {
        // Could probably just use an aspect ratio constraint and set the constant equal to ratio, but
        // this works and I don't want to break it
        var photoURLString = ""

        let ratio = post!.imageAspectRatio
        
        if self.showThumb == true && post?.thumbURL != nil {
            photoURLString = post!.thumbURL!
        }
        else {
            photoURLString = post!.photoURL
        }

        if photoURLString != "" {
            postImageView.alpha = 1.0
            
            if API.Post.newPost != nil {
                if self.post?.postID == API.Post.newPost.postID {
                    postImageView.sd_setImage(with: URL(string: photoURLString), placeholderImage: API.Post.newPost.postImage, options: .retryFailed ){ (_, _, _, _) in
                    }
                }
                else {
                    postImageView.sd_setImage(with: URL(string: photoURLString)) { (image, error, _, _) in
                        guard let image = image else { return }
                        let imageRatio = image.size.width / image.size.height
                        print("ANDREWTEST: Just double checking the image aspect ratio: \(imageRatio) and this is the cell aspect ratio: \(ratio)")
                    }
                }
            }
            else {
                postImageView.sd_setImage(with: URL(string: photoURLString)) { (image, error, _, _) in
                    guard let image = image else { return }
                    let imageRatio = image.size.width / image.size.height
                    print("ANDREWTEST: Just double checking the image aspect ratio: \(imageRatio) and this is the cell aspect ratio: \(ratio)")
                    
                    if self.post?.photoURL != nil && self.post?.thumbURL == nil{
                        print("image width height ", image.size.width, image.size.height)
                        API.Post.addMissingThumbnail(postWithID: self.post!.postID, forPostURL: self.post!.photoURL, forWidth: Int(image.size.width*0.5), forHeight: Int(image.size.height*0.5))
                    }
                }
            }
        }
        else if post?.postImage != nil {
            postImageView.image = post?.postImage
            postImageView.alpha = 0.4
        }
    }
    
    /// Called when the user is set, just some UI setup
    func updateUserInfo() {
        formatUsernameLabel()
        if let photoURLString = user?.profileImageURL {
//            profileImageView.sd_setImage(with: URL(string: photoURLString), completed: nil)
            profileImageView.showLoading()
            profileImageView.sd_setImage(with: URL(string: photoURLString)) { (outImg, error, type, url) in
                self.profileImageView.hideLoading()
            }
        }
        
        API.Follow.isFollowing(userID: user!.uid) { (value) in
            self.user!.isFollowing = value
        }
        
    }
    
    /// Formats the username label to include the user and strip name
    func formatUsernameLabel() {
        if let post = post, let user = user {
            let boldText = user.username
            let attrs = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17)]
            let attributedString = NSMutableAttributedString(string: boldText, attributes: attrs)
            
            if user.isVerified {
                verifiedImageView.isHidden = false
            }else{
                verifiedImageView.isHidden = true
            }

            nameLabel_Title.attributedText = attributedString
            
            let normalText = "\nadded to "
            let attrs2 = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 17)]
            let normalString = NSMutableAttributedString(string: normalText, attributes: attrs2)
            
            let boldText2 = post.stripName
            let attributedString2 = NSMutableAttributedString(string: boldText2, attributes: attrs)
            
            attributedString.append(normalString)
            attributedString.append(attributedString2)
            
            nameLabel.attributedText = attributedString
        }
    }

    /// Segues to the user's profile when their photo/name are tapped
    @IBAction func usernameProfileButtonPressed(_ sender: Any) {
        print("Segue to user's profile")
        if user != nil {
            delegate?.usernameProfileButtonPressed(user: user!)
        }
    }
    
    @IBAction func userStripeButtonPressed(_ sender: Any) {
        print("Segue to user's strip")
        API.Strip.observeStrip(withID: post?.stripID ?? "") { (strip) in
            self.delegate?.userStripeButtonPressed(user: self.user!, strip: strip)
        }
    }
    
    /// Called in ViewPostViewController when that post is being edited, takes care of the UI stuff
    func startEditing() {
        print("BUG3: Started editing post")
        captionTextView.isHidden = true
        postImageView.isUserInteractionEnabled = false
        ellipsisButton.isHidden = true
        editableTextView.isEditable = true
        editableTextView.isHidden = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        myScrollView.delegate = self
        self.layoutIfNeeded()
    }
    
    /// Shortens the caption and gives the read more option, this is never called from ViewPostViewController because
    /// it's fine if we have the full caption there
    func truncateCaption() {
        captionTextView.resolveHashtagsAndMentions()
        captionTextView.shouldTrim = true
        captionTextView.maximumNumberOfLines = 2
        captionTextView.attributedReadMoreText = NSAttributedString(string: "... read more", attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
        captionTextView.attributedReadLessText = NSAttributedString(string: " read less", attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17)!, NSAttributedString.Key.foregroundColor: UIColor.white])
        captionTextView.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        captionTextView.textColor = UIColor.white
    }
    
    /// Updates the UI on this post to match the likes of the parameter passed into this method
    func updateLike(post: StripwayPost) {
        if post.isLiked {
            likeImageView.image = #imageLiteral(resourceName: "Like Picture Selected")
            if let bigLikeImageV = likeImageView {
                    UIView.animate(withDuration: 0.12, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: .allowUserInteraction, animations: {
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                        bigLikeImageV.alpha = 0.9
                    }) { finished in
                        bigLikeImageV.alpha = 1.0
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
            }
        } else {
            likeImageView.image = #imageLiteral(resourceName: "Like Picture")
        }
        likesNumberButton.setTitle("\(post.likeCount)", for: .normal)
    }
    
    /// Updates the UI on this post to match the reposts of the parameter passed into this method
    func updateRepost(post: StripwayPost) {
        if post.isReposted {
            repostImageView.image = #imageLiteral(resourceName: "Repost Picture Selected")
        } else {
            repostImageView.image = #imageLiteral(resourceName: "Repost Picture")
        }
        repostsNumberButton.setTitle("\(post.repostCount)", for: .normal)
    }
    
    /// Updates the UI on this post to match the bookmarks of the parameter passed into this method
    func updateBookmark(post: StripwayPost) {
        if post.isBookmarked {
            bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture Selected")
        } else {
            bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture")
        }
    }
    
    /// Changes the like in the database and updates the UI
    @objc func likeButtonPressed() {
        
        likeImageView.isUserInteractionEnabled = false
        API.Post.incrementLikes(postID: post!.postID) { (post, error) in
            self.likeImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateLike(post: post)
                self.post?.likes = post.likes
                self.post?.isLiked = post.isLiked
                self.post?.likeCount = post.likeCount
            }
        }
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Changes the repost in the database and updates the UI
    @objc func repostButtonPressed() {
        repostImageView.isUserInteractionEnabled = false
        API.Post.incrementReposts(postID: post!.postID) { (post, error) in
            self.repostImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateRepost(post: post)
                self.post?.reposts = post.reposts
                self.post?.isReposted = post.isReposted
                self.post?.repostCount = post.repostCount
            }
        }
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Changes the bookmark in the database and updates the UI
    @objc func bookmarkButtonPressed() {
        print("bookmark button pressed")
        bookmarkImageView.isUserInteractionEnabled = false
        
        API.Post.incrementBookmarks(postID: post!.postID) { (post, error) in
            self.bookmarkImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateBookmark(post: post)
                self.post?.bookmarks = post.bookmarks
                self.post?.isBookmarked = post.isBookmarked
                self.post?.bookmarkCount = post.bookmarkCount
            }
        }
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Segues to the PeopleViewController (from the delegate) and shows the likers of the post
    @IBAction func likesNumberButtonPressed(_ sender: Any) {
        delegate?.viewLikersButtonPressed(post: post!)
    }
    
    /// Segues to the PeopleViewController (from the delegate) and shows the reposters of the post
    @IBAction func repostsNumberButtonPressed(_ sender: Any) {
        delegate?.viewRepostersButtonPressed(post: post!)
    }
    
    /// Segues to the CommentViewController (from the delegate) and shows the comments for the post
    @IBAction func commentsNumberButtonPressed(_ sender: Any) {
        self.commentButtonPressed()
    }
    
    /// Segues to the CommentViewController (from the delegate) and shows the comments for the post
    @objc func commentButtonPressed() {
        delegate?.commentButtonPressed(post: post!)
    }
    
    @IBAction func toggleSpotted(_ sender: UIButton) {
        
        if !taggedVisible {//show
            guard let post = post else {return}
            for (_,value) in post.tags{
                if let value = value as? [String:Any], let x = value["x"] as? CGFloat, let y = value["y"] as? CGFloat, let username = value["username"] as? String{
                    
                    let myText = username
                    
                    let rect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:  UIFont.systemFont(ofSize: 14)], context: nil)
                    
                    
                    let button = UIButton(frame: CGRect(x: x, y: y, width: labelSize.width + 30, height: 28))
                    button.setTitle("@" + username, for: .normal)
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    button.backgroundColor = UIColor.black
                    button.alpha = 0.7
                    button.layer.cornerRadius = 14
                    button.clipsToBounds = true
                    postImageView.addSubview(button)
                    
                    taggedButtons.append(button)
                }
            }
            
            taggedVisible = true
        }else{//hide
            
            _ = taggedButtons.map({$0.removeFromSuperview()})
            taggedButtons = []
            
            taggedVisible = false
        }
        
    }
    
    
    /// Shows the image full-screen when the postImageView is tapped, presesnts it from the delegate
    @objc func showImage() {
        print("showImage called form inside HomeTableViewCell")
        if let image = postImageView.image {
            print("Should be showing the image")
            let postImage = PostImage()
            postImage.image = image
            
            let dataSource = NYTPhotoViewerSinglePhotoDataSource(photo: postImage)
            let photosVC = NYTPhotosViewController(dataSource: dataSource)
            photosVC.rightBarButtonItem = nil
            photosVC.overlayView?.captionView?.isHidden = true
            photosVC.additionalSafeAreaInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: -200, right: 0)
            delegate?.presentImageVC(imageVC: photosVC)
        }
    }
    
    /// Resets some views so new cells don't have data from previous posts
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil

        likeImageView.image = #imageLiteral(resourceName: "Like Picture")
        repostImageView.image = #imageLiteral(resourceName: "Repost Picture")
        bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture")
        
        likesNumberButton.setTitle("0", for: .normal)
        repostsNumberButton.setTitle("0", for: .normal)
    }
    
    /// Options for a post depend on the user that presses the button
    @IBAction func ellipsisButtonPressed(_ sender: Any) {
        guard let user = user else { return }
        if user.isFollowing == nil { return }
        
        // Post owner can edit the post, everyone else can follow/unfollow/block
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if user.isCurrentUser {
            alertController.addAction(UIAlertAction(title: "Edit", style: .default, handler: { (action) in
                self.delegate?.startEditingPost(post: self.post!)
            }))
            alertController.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action) in
                let deleteAlert = UIAlertController(title: "Delete Post?", message: "Are you sure you want to delete this post? This cannot be undone.", preferredStyle: .alert)
                deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    if let post = self.post {
                        API.Post.deletePost(post: post)
                        self.delegate?.postDeleted(post: post)
                    }
                }))
                self.delegate?.presentAlertController(alertController: deleteAlert, forCell: self)
            }))
        } else {
            if user.isFollowing! {
                alertController.addAction(UIAlertAction(title: "Unfollow", style: .default, handler: { (action) in
                    self.unfollowUser(user: user)
                }))
            } else {
                alertController.addAction(UIAlertAction(title: "Follow", style: .default, handler: { (action) in
                    self.followUser(user: user)
                }))
            }
            alertController.addAction(UIAlertAction(title: "Block User", style: .default, handler: { (action) in
                print("Should be blocking this user")
                API.Block.blockUser(withUID: user.uid)
            }))
            alertController.addAction(UIAlertAction(title: "Report Post", style: .default, handler: { (action) in
                print("Should be reporting this post")
                if let post = self.post {
                    API.Post.reportPost(post: post)
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "Share", style: .default, handler: { (action) in
            print("Should be reporting this post")
            if let post = self.post {
                self.delegate?.presentPeopleSelectionController(post: post)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.tintColor = UIColor.black
        delegate?.presentAlertController(alertController: alertController, forCell: self)
    }
    
    /// Current user follows the post owner
    func followUser(user: StripwayUser) {
        if user.isFollowing! == false {
            API.Follow.followAction(withUser: user.uid)
            user.isFollowing! = true
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Current user unfollows the post owner
    func unfollowUser(user: StripwayUser) {
        print("Unfollowing \(user.username)")
        if user.isFollowing! == true {
            API.Follow.unfollowAction(withUser: user.uid)
            user.isFollowing! = false
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

extension PostTableViewCell: UITextViewDelegate {
    
    /// Adjusts the caption view stuff when the text changes in it
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        adjustFrames()
        return true
    }
    
    /// Adjusts the caption view stuff when the text changes in it (not sure if calling it again here is necessary)
    /// Also passes the current word to the delegate
    func textViewDidChange(_ textView: UITextView) {
        adjustFrames()
        delegate?.currentWordBeingTyped(word: textView.currentWord)
    }
    
    /// This works but it's very CPU intensive os ideally find a better way
    /// Basically makes sure that we always know the location of the bottom of the textView
    func adjustFrames() {
        var frame = self.editableTextView.frame
        if captionTextView.text.isEmpty {
            frame.size.height = 0
        } else {
            frame.size.height = self.editableTextView.contentSize.height
        }
        self.editableTextView.frame = frame
        captionMaxY = editableTextView.frame.maxY
        delegate?.textViewChanged()
    }
    
    /// Allows user to interact with hashtags and mentions and segues to the appropriate screen from the delegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var newURL = URL.absoluteString
        let segueType = newURL.prefix(4)
        newURL.removeFirst(5)
        if segueType == "hash" {
            delegate?.segueToHashtag(hashtag: newURL)
        } else if segueType == "user" {
            delegate?.segueToProfileFor(username: newURL)
        }
        return false
    }
    
    /// Used in ViewPostViewController when the vc is peeked, show only the photo
    func hidePhotoOverlay() {
//        self.contentView.bringSubviewToFront(postImageView)
        profileImageView.isHidden = true
        nameLabel.isHidden = true
        captionTextView.isHidden = true
        editableTextView.isHidden = true
        timestampLabel.isHidden = true
        likeImageView.isHidden = true
        commentImageView.isHidden = true
        repostImageView.isHidden = true
        bookmarkImageView.isHidden = true
        ellipsisButton.isHidden = true
        likesNumberButton.isHidden = true
        commentsNumberButton.isHidden = true
        repostsNumberButton.isHidden = true
        
    }
    
    /// Used in ViewPostViewController when the vc is popped, show the stuff over the photo
    func showPhotoOverlay() {
//        self.contentView.sendSubviewToBack(postImageView)
        profileImageView.isHidden = false
        nameLabel.isHidden = false
        captionTextView.isHidden = false
        editableTextView.isHidden = false
        timestampLabel.isHidden = false
        likeImageView.isHidden = false
        commentImageView.isHidden = false
        repostImageView.isHidden = false
        bookmarkImageView.isHidden = false
        ellipsisButton.isHidden = false
        likesNumberButton.isHidden = false
        commentsNumberButton.isHidden = false
        repostsNumberButton.isHidden = false
    }
}

protocol PostTableViewCellDelegate {
    func presentPeopleSelectionController(post: StripwayPost)
    func presentImageVC(imageVC: NYTPhotosViewController)
    func textViewChanged()
    func commentButtonPressed(post: StripwayPost)
    func usernameProfileButtonPressed(user: StripwayUser)
    func userStripeButtonPressed(user: StripwayUser, strip: StripwayStrip)
    func viewLikersButtonPressed(post: StripwayPost)
    func viewRepostersButtonPressed(post: StripwayPost)
    func presentAlertController(alertController: UIAlertController, forCell cell: PostTableViewCell)
    func startEditingPost(post: StripwayPost)
    func segueToHashtag(hashtag: String)
    func segueToProfileFor(username: String)
    func currentWordBeingTyped(word: String?)
    func postDeleted(post: StripwayPost)
}

class PostImage: NSObject, NYTPhoto {
    var image: UIImage?
    var imageData: Data?
    var placeholderImage: UIImage?
    var attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString?
    var attributedCaptionCredit: NSAttributedString?
}

extension PostTableViewCell : UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("Lavaneesh :- \(scrollView.contentOffset.x)")
        //self.post = postsModelArr[scrollView.tag]
//        DispatchQueue.main.async {
//            UIView.animate(withDuration: 0.4, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
//                self.myScrollView.center.x = self.myScrollView.center.x - 1
//            }, completion: nil)
//        }
        let x = myScrollView.contentOffset.x
        let w = myScrollView.bounds.size.width
        pageControll.currentPage = Int(x/w)

    }
    
}
