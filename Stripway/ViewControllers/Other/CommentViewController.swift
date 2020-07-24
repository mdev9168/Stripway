//
//  CommentViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CommentViewController: UIViewController {

    @IBOutlet weak var scrollTopView: UIView!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet var tableViewTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIButton!
    
    var post: StripwayPost!
    
    var comments: [StripwayComment] = []
    var users: [StripwayUser] = []
    var accurateUsers: [String: StripwayUser] = [:]
    
    @IBOutlet weak var commentsNumberLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var tappedUser: StripwayUser!
    
    var delegate: CommentViewControllerDelegate?
    var commentHandle:DatabaseHandle!
    
    @IBOutlet weak var suggestionsContainerView: UIView!
    var suggestionsTableViewController: SuggestionsTableViewController?

    var mentionedUIDs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableView.automaticDimension
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let commentsRef = API.Comment.postCommentsReference.child(post!.postID)
        if commentHandle != nil {
            commentsRef.removeObserver(withHandle: commentHandle)
        }
        commentHandle = commentsRef.observe(.value) { (snapshot) in
            let numberOfComments = snapshot.childrenCount
            self.commentsNumberLabel.text = "\(numberOfComments) comments"
        }
        
        handleTextField()
        loadComments()
    }
    
    func handleTextField() {
//        textView.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
    }
    
    func loadComments() {
//        API.Comment.observeComments(withPostID: self.post.postID) { (comment) in
//            // could maybe add an isBlocked to the observeUser since it doesn't add untikl later
//            // also should we maybe just return both at the same time anyway?
//            API.User.observeUser(withUID: comment.authorUID, completion: { (user) in
//                self.comments.append(comment)
//                print("Here's the timestamp for the new comment: \(comment.timestamp)")
//                print("Also here's the commentID: \(comment.commentID)")
//                self.users.append(user)
//                self.accurateUsers[user.uid] = user
//                self.tableView.reloadData()
//            })
//        }
        
        API.Comment.observeComments(forPostID: self.post.postID) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let result = result else { return }
            let comment = result.0
            let user = result.1
            
            self.comments.append(comment)
            self.users.append(user)
            self.accurateUsers[user.uid] = user
            self.tableView.reloadData()
        }
        
        // this will mess up the order of users, that needs to be fixed too
        API.Comment.observeCommentRemoved(forPostID: post.postID) { (key) in
//            print("This is the removed comment: \(key)")
////            self.comments = self.comments.filter{ $0.commentID != key }
//            let index = self.comments.firstIndex(where: { $0.commentID == key })
//            print("THIS IS THE REMOVED INDEX OF THE COMMENT: \(index)")
            self.tableView.reloadData()
        }
    }
    
    @objc func textFieldDidChange() {
        if let commentText = textView.text, !commentText.isEmpty {
            postButton.isEnabled = true
            return
        }
        postButton.isEnabled = false
        return
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizer.State.ended {
            let velocity = recognizer.velocity(in: self.view)
            
            if (velocity.y > VELOCITY_LIMIT_SWIPE) {
                textView.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }
            
            let magnitude = sqrt(velocity.y * velocity.y)
            let slideMultiplier = magnitude / 200
            
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            var finalPoint = CGPoint(x:recognizer.view!.center.x,
                                     y:recognizer.view!.center.y + (velocity.y * slideFactor))
            finalPoint.x = min(max(finalPoint.x, 0), self.view.bounds.size.width)
            
            let finalY = recognizer.view!.center.y
            if finalY < UIScreen.main.bounds.height {
                finalPoint.y = UIScreen.main.bounds.height * 0.625
            }
            else {
                textView.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }
            
            UIView.animate(withDuration: Double(slideFactor),
                           delay: 0,
                           // 6
                options: UIView.AnimationOptions.curveEaseOut,
                animations: {recognizer.view!.center = finalPoint },
                completion: nil)
        }
        
        let translation = recognizer.translation(in: self.view)
        
        if let view = recognizer.view {
            print("translation Y", translation.y)
                view.center = CGPoint(x:view.center.x,
                                      y:view.center.y + translation.y)
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }

    func setupUI() {
        bottomView.layer.cornerRadius = 20
        bottomView.layer.shadowOffset = CGSize(width: 4, height: 4)
        bottomView.layer.shadowRadius = 6
        bottomView.layer.shadowOpacity = 0.5
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        tableViewTapGestureRecognizer.isEnabled = false
//        super.viewWillDisappear(animated)
//        self.dismiss(animated: animated, completion: nil)
//        print("viewWillDisappear so dismissing CommentViewController")
//    }
    
    @IBAction func topViewTapped(_ sender: Any) {
        textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tableViewGestureTapped(_ sender: Any) {
        textView.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        tableViewTapGestureRecognizer.isEnabled = true
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        print("Here's keyboardFrame in keyboardWillShow: \(keyboardFrame)")
        let difference = bottomView.superview!.frame.maxY - bottomView.frame.maxY
        
        UIView.animate(withDuration: 0.05) {
            self.textFieldBottomConstraint.constant = keyboardFrame.size.height - difference - 150
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide() {
        UIView.animate(withDuration: 0.05) {
            self.textFieldBottomConstraint.constant = -150
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        postButton.isEnabled = false
        
        API.Comment.createComment(forPostID: self.post.postID, fromPostAuthor: self.post.authorUID, withText: textView.text ?? "", commentAuthorID: Constants.currentUser!.uid, withMentions: mentionedUIDs) {
            self.postButton.isEnabled = true
            self.empty()
        }
    }
    
    func empty() {
        textView.text = "Write a comment..."
        textView.tag = 0
        textView.textColor = UIColor.lightGray
        textFieldDidChange()
        textView.resignFirstResponder()
    }
    

    @IBAction func xButtonPressed(_ sender: Any) {
        textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}

extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sortedComments = comments.sorted(by: { $0.timestamp < $1.timestamp })
//        let testUsers: [String: StripwayUser] = [:]
//        let theComment = comments[indexPath.row]
//        cell.user = testUsers[theComment.authorUID]

        let comment = sortedComments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath) as! CommentTableViewCell
        cell.comment = comment
        cell.user = accurateUsers[comment.authorUID]
        cell.delegate = self
        cell.postAuthorUID = post.authorUID
        return cell
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath) as! CommentTableViewCell
//        cell.comment = comments[indexPath.row]
//        cell.user = users[indexPath.row]
//        cell.delegate = self
//        cell.postAuthorUID = post.authorUID
//        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let sortedComments = comments.sorted(by: { $0.timestamp < $1.timestamp })
        let currentUserUID = Constants.currentUser!.uid
        let commentAuthorUID = sortedComments[indexPath.row].authorUID
        let postAuthorUID = post.authorUID

        if currentUserUID == postAuthorUID || currentUserUID == commentAuthorUID {
            print("TEST2: Should be allowed to delete for: \(sortedComments[indexPath.row].commentText)")
            return .delete
        }
        print("TEST2: Not allowed to delete for: \(sortedComments[indexPath.row].commentText)")
        return .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let sortedComments = comments.sorted(by: { $0.timestamp < $1.timestamp })
        print("deleting comment with text: \(sortedComments[indexPath.row].commentText)")
        let deletedComment = sortedComments[indexPath.row]
        API.Comment.deleteComment(withID: deletedComment.commentID, fromPost: post.postID)
        if let index = comments.firstIndex(where: { $0.commentID == deletedComment.commentID }) {
            comments.remove(at: index)
            users.remove(at: index)
            tableView.reloadData()
        }
    }
    
}

extension CommentViewController: CommentTableViewCellDelegate {
    func usernameProfileButtonPressed(user: StripwayUser) {
//        self.tappedUser = user
//        performSegue(withIdentifier: "ShowUserProfile", sender: self)
        delegate?.userProfilePressed(user: user, fromVC: self)
    }
    
    func deleteComment(withID commentID: String) {
        // this could probably be better, idk
        API.Comment.deleteComment(withID: commentID, fromPost: post.postID)
        if let index = comments.firstIndex(where: { $0.commentID == commentID }) {
            comments.remove(at: index)
            users.remove(at: index)
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUserProfile" {
            if let profileViewController = segue.destination as? ProfileViewController, let user = tappedUser {
//                profileViewController.profileOwnerUID = user.uid
                profileViewController.profileOwner = user
            }
        }
        if segue.identifier == "SuggestionsContainerSegue" {
            if let suggestionsTableViewController = segue.destination as? SuggestionsTableViewController {
                self.suggestionsTableViewController = suggestionsTableViewController
                suggestionsTableViewController.delegate = self
            }
        }
    }
    
}

extension CommentViewController: SuggestionsTableViewControllerDelegate {

    func autoComplete(withSuggestion suggestion: String, andUID uid: String?) {
        print("replacing with suggestion")
        textView.autoComplete(withSuggestion: suggestion)
        self.textViewDidChange(textView)

        if let uid = uid {
            mentionedUIDs.append(uid)
        }
    }

//    func autoComplete(withSuggestion suggestion: String) {
//        print("replacing with suggestion")
//        textView.autoComplete(withSuggestion: suggestion)
//        self.textViewDidChange(textView)
//    }
}

extension CommentViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var newURL = URL.absoluteString
        let segueType = newURL.prefix(4)
        newURL.removeFirst(5)
        if segueType == "hash" {
            print("Should segue to page for hashtag: \(newURL)")
            delegate?.segueToHashtag(hashtag: newURL, fromVC: self)
        } else if segueType == "user" {
            print("Should segue to profile for user: \(newURL)")
            delegate?.segueToProfileFor(username: newURL, fromVC: self)
        }
        return false
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
        if textView.tag == 0 {
            textView.tag = 1
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        textFieldDidChange()
        guard let word = textView.currentWord else {
            suggestionsContainerView.isHidden = true
            return
        }
        guard let suggestionsTableViewController = self.suggestionsTableViewController else { return }
        if word.hasPrefix("#") || word.hasPrefix("@") {
            suggestionsTableViewController.searchWithText(text: word)
            suggestionsContainerView.isHidden = false
        } else {
            suggestionsContainerView.isHidden = true
        }
    }
}

extension CommentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("This thing should run")
        //detecting a direction
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = recognizer.velocity(in: self.view)
            
            if abs(velocity.y) > abs(velocity.x) {
                // this is swipe up/down so you can handle that gesture
                return true
            } else {
                //this is swipe left/right
                //do nothing for that gesture
                return false
            }
        }
        return true
    }
    
//    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        //detecting a direction
//        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {
//            let velocity = recognizer.velocity(in: self.view)
//
//            if fabs(velocity.y) > fabs(velocity.x) {
//                // this is swipe up/down so you can handle that gesture
//                return true
//            } else {
//                //this is swipe left/right
//                //do nothing for that gesture
//                return false
//            }
//        }
//        return true
//    }
}

protocol CommentViewControllerDelegate {
    func userProfilePressed(user: StripwayUser, fromVC vc: CommentViewController)
    func segueToHashtag(hashtag: String, fromVC vc: CommentViewController)
    func segueToProfileFor(username: String, fromVC vc: CommentViewController)
}
