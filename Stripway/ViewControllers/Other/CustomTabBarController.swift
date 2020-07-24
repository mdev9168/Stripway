//
//  CustomTabBarController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/30/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Photos
import CropViewController
import FirebaseAuth

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {

    // Image chosen from image picker and passed to NewPostViewController
    var imageForNewPost: UIImage?
    var imageAspectRatioForNewPost: CGFloat = 0.75
    var addingToNewStrip = false
    var futureSelectedIndex = 0
    var wasNewPostPosted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        // Do any additional setup after loading the view.
        self.tabBar.alpha = 0.95
    }
    
    func newPostPosted() {
        print("Running newPostPosted() in CustomTabBarViewController")
        wasNewPostPosted = true
        self.selectedIndex = 0
        print("Running: tabBarController.viewControllers: \(tabBarController?.viewControllers)")        
        
//        guard let homeViewController = tabBarController?.viewControllers?.first as? HomeViewController else {
//            print("Running: Apparently tabBarController?.viewControllers?.first is not HomeViewController")
//            return
//        }
//        homeViewController.newPostPosted(post, postAuthor)
    }
    
    func cancelPosted() {
        self.selectedIndex = 0
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("Custom should select happening, switching to viewController: \(NSStringFromClass(viewController.classForCoder))")
    
        let selectedTabIndex = tabBarController.viewControllers?.firstIndex(of: viewController)
        self.futureSelectedIndex = selectedTabIndex ?? 0
        print("Selected tab: \(selectedTabIndex)")
        
        if selectedTabIndex == 2 {
            goNewPostViewController()
//            let pickerController = UIImagePickerController()
//            pickerController.delegate = self
//            pickerController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//            self.present(pickerController, animated: true, completion: nil)
            return false
        }
        
        
        // If selected view controller is the same one we're already on
        if tabBarController.selectedViewController!.isEqual(viewController) {
            
            // Scroll to the top
            print("Should be scrolling to the top")
            if let navigationController = viewController as? UINavigationController {
                if let homeViewController = navigationController.viewControllers.first as? HomeViewController {
                    print("Custom thing should be scrolling home view to top")
                    homeViewController.scrolltoTop()
                    
//                    homeViewController.tableView.setContentOffset(.zero, animated: true)
//                    homeViewController.tableView.contentOffset.y = -64.0
//                    homeViewController.tableView.sendSubviewToBack(self.view)
//                    self.navigationController?.setNavigationBarHidden(false, animated: true)
//                    homeViewController.tableView.setContentOffset(.zero, animated: true)
//                    homeViewController.tableView.setContentOffset(CGPoint(x:0.0, y:64.0), animated: true)

                } else if let profileViewController = navigationController.viewControllers.first as? ProfileViewController {
                    profileViewController.tableView.setContentOffset(.zero, animated: true)
                    print("Custon thing should be scrolling profile view to top")
                }
                else if let searchViewController = navigationController.viewControllers.first as? SearchViewController {
                   
                   ///Resets search controller when tab bar button is clicked again
                    searchViewController.searchBarCancelButtonClicked(searchViewController.searchBar)
                        searchViewController.currentTab = 0
                        searchViewController.tabChanged()
                }
            
            }
        }
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Store current navigation controller in the appDelegate so notifications can present stuff correctly
        if let currentNavController = viewController as? UINavigationController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentNavController = currentNavController
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CustomTabBarController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
    /// This helper method makes sure we actually have permission to view the user's photo library, maybe add a .denied case 
    func checkPermissions(completion: @escaping ()->()) {
        print("Checking permissions")
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            // Access already granted
            print("access has already been granted by user")
            completion()
        case .notDetermined:
            // Access not granted, so we must request it
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    // access granted by user
                    print("access granted by user")
                    completion()
                }
            }
        default:
            print("Error: no access to photo album")
            let alert = UIAlertController(title: "Error", message: "No access to photo album. Please allow Stripway to access your photos in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // Once an image has been successfully picked from the library, pass it to the cropViewController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        print("Did finish picking media")
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            print("Something went wrong with the image picker")
            dismiss(animated: true, completion: nil)
            return
        }
        
        dismiss(animated: true) {
            self.presentCropViewController(withImage: image)
            
        }
    }
    
    // This helper method determines what kind of cropping we're going to be doing
    func presentCropViewController(withImage image: UIImage) {
    
        // If it's a new post, it must have a 3:4 width:height ratio (like default iOS ratio)
        let cropViewController = TOCropViewController(croppingStyle: .default, image: image)
        cropViewController.delegate = self
        cropViewController.aspectRatioPreset = .presetCustom
        cropViewController.minimumAspectRatio = IMAGE_CROP_RATIO
        cropViewController.aspectRatioPickerButtonHidden = true
//        cropViewController.aspectRatioLockDimensionSwa pEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.customAspectRatio = CGSize(width: 3, height: 4)
//        let customRatio:CGFloat = max(IMAGE_CROP_RATIO, image.size.width/image.size.height)
//        cropViewController.customAspectRatio = CGSize(width: customRatio, height: 1)

        present(cropViewController, animated: true, completion: nil)
        
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        dismiss(animated: true, completion: nil)
        
        // Pass the image to the new post view controller
        imageForNewPost = image
        imageAspectRatioForNewPost = cropRect.width / cropRect.height
        print("ANDREWTEST: This is the aspect ratio: \(imageAspectRatioForNewPost)")
        //        performSegue(withIdentifier: "NewPostSegue", sender: self)
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "NewPostViewController") as! NewPostViewController
        newPostViewController.imageToPost = imageForNewPost
        newPostViewController.imageAspectRatio = imageAspectRatioForNewPost
        API.User.observeCurrentUser { (currentUser) in
            newPostViewController.postAuthor = currentUser
            newPostViewController.customTabBarController = self
            self.present(newPostViewController, animated: true, completion: nil)
        }
    }
    
    func goNewPostViewController() {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "NewMainPostViewController") as! NewMainPostViewController
//        newPostViewController.imageToPost = imageForNewPost
//        newPostViewController.imageAspectRatio = imageAspectRatioForNewPost
//        API.User.observeCurrentUser { (currentUser) in
//            newPostViewController.postAuthor = currentUser
//            newPostViewController.customTabBarController = self
//            self.present(newPostViewController, animated: true, completion: nil)
//        }
        newPostViewController.customTabBarController = self
        newPostViewController.modalPresentationStyle = .fullScreen
        self.present(newPostViewController, animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        super.dismiss(animated: true, completion: nil)
        self.cancelPosted()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
