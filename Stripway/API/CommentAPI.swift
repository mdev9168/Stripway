//
//  CommentAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// The way that comments work is a little convoluted and needs to be redone. "post-comments" in the database has a list of postIDs and under them
/// is a list of commentIDs for the comments on that post. But then you have to look up the comment using that commentID in the "comments" part of the database, it's not actually under the
/// postID. Ideally it would just be "post-comments" with the list of postIDs and under them are the full comments (user, commentText, likes, etc) so we'll need to do that eventually.
class CommentAPI {
    
    /// Where the full comments are on the database
    var commentsReference = Database.database().reference().child("comments")
    /// Where the commentIDs are matched to the postIDs in the database.
    /// TODO: Just put the full comment in "post-comments" and not just the commentID
    var postCommentsReference = Database.database().reference().child("post-comments")
    var commentsCountHandle:DatabaseHandle!

    /// Adds a comment to a post
    func createComment(forPostID postID: String, fromPostAuthor postAuthorID: String, withText commentText: String, commentAuthorID: String, withMentions mentions: [String], completion: @escaping()->()) {
        let newCommentID = commentsReference.childByAutoId().key!
        let newCommentReference = commentsReference.child(newCommentID)
        let currentUserUID = Constants.currentUser!.uid
        let timestamp = Int(Date().timeIntervalSince1970)
        let newComment = StripwayComment(commentID: newCommentID,commentText: commentText, authorUID: commentAuthorID, timestamp: timestamp)
        // TODO: Use multipath for this
        // Creates a new comment and adds it to database
        newCommentReference.setValue(newComment.toAnyObject()) { (error, ref) in
            if let error = error {
                print("here's an error: \(error.localizedDescription)")
            }
            // Matches the comment with the post it belongs to and adds a timestamp as well
            self.postCommentsReference.child(postID).child(newCommentID).setValue(["timestamp": timestamp], withCompletionBlock: { (error, ref) in
                if let error = error {
                    print("here's an error: \(error.localizedDescription)")
                }
                API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: postAuthorID, objectID: postID, type: .comment, commentText: newComment.commentText)
                completion()
                
                // Notify mentions
                
                // Remove duplicates from mentions
                let newMentions = Array(Set(mentions))
                for uid in newMentions {
                    API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: uid, objectID: postID, type: .commentMention, commentText: newComment.commentText)
                }
            })
        }
    }
    
    /// Increments likes on a comment
    func incrementLikes(commentID: String, completion: @escaping(StripwayComment?, Error?)->()) {
        let ref = commentsReference.child(commentID)
        ref.runTransactionBlock({ (currentData) -> TransactionResult in
            if var comment = currentData.value as? [String: AnyObject], let uid = Constants.currentUser?.uid {
                var likes: Dictionary<String, Bool>
                likes = comment["likes"] as? [String: Bool] ?? [:]
                var likeCount = comment["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                } else {
                    likeCount += 1
                    likes[uid] = true
                }
                comment["likeCount"] = likeCount as AnyObject?
                comment["likes"] = likes as AnyObject?
                
                currentData.value = comment
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let comment = StripwayComment(snapshot: snapshot!)
                completion(comment, nil)
            }
        }
    }
    
    /// Observes comments for a post
    func observeComments(forPostID postID: String, completion: @escaping((StripwayComment, StripwayUser)?, Error?)->()) {
        // Finds which comments belong to the post
        postCommentsReference.child(postID).queryOrdered(byChild: "timestamp").observe(.childAdded) { (snapshot) in
            // Observe the actual comment itself
            self.commentsReference.child(snapshot.key).observeSingleEvent(of: .value, with: { (commentSnapshot) in
                let comment = StripwayComment(snapshot: commentSnapshot)
                // Observe the author of the comment
                API.User.observeUser(withUID: comment.authorUID, completion: { (user, error) in
                    if let error = error {
                        completion(nil, error)
                    } else if let user = user {
                        if user.isBlocked || user.hasBlocked {
                            let error = CustomError("This user is blocked")
                            completion(nil, error)
                        } else {
                            print("observing comment: \(comment.commentText)")
                            completion((comment, user), nil)
                        }
                    }
                })
            })
        }
    }
    
    func deleteComment(withID commentID: String, fromPost postID: String) {
        let commentReference = commentsReference.child(commentID)
        commentReference.removeValue()
        
        let postCommentReference = postCommentsReference.child(postID).child(commentID)
        postCommentReference.removeValue()
    }
    
    /// Observes removed comments (mainly so it immediately shows when you delete your own comment)
    func observeCommentRemoved(forPostID postID: String, completion: @escaping (String)->()) {
        postCommentsReference.child(postID).observe(.childRemoved) { (snapshot) in
            let key = snapshot.key
            completion(key)
        }
    }
    
    func observeCommentCount(forPostID postID: String, completion: @escaping (UInt)->()) {
        
        let perPostCommentsReference:DatabaseQuery = postCommentsReference.child(postID)
        if commentsCountHandle != nil {
            perPostCommentsReference.removeObserver(withHandle: commentsCountHandle)
        }
        
        commentsCountHandle = perPostCommentsReference.observe(.value) { (snapshot) in
            let numberOfComments = snapshot.childrenCount
            completion(numberOfComments)
        }
    }
    
}
