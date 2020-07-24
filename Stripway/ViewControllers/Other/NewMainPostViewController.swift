//
//  NewMainPostViewController.swift
//  Stripway
//
//  Created by Troy on 5/2/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit
import Photos
import DKImagePickerController
import PageMaster


class NewMainPostViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, DKImageAssetExporterObserver, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NewImageViewControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var customTabBarController: CustomTabBarController!
    static let vc = self
    
    var pickerController: DKImagePickerController!
    var images: [UIImage] = []
    var selectedImage = 1
    var image: UIImage = UIImage()
    private let pageMaster = PageMaster([])
    
    private var newImageViewController: NewImageViewController = NewImageViewController()
    private var newCaptionViewController: NewCaptionViewController = NewCaptionViewController()
    private var newHashTagViewController: NewHashTagViewController = NewHashTagViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageMaster()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        DispatchQueue.main.async {
            self.fetchPhotos()
        }
//        self.registerKeyboardNotifications()
    }
    
    private func setupPageMaster() {
        self.pageMaster.pageDelegate = self
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        newImageViewController = storyBoard.instantiateViewController(withIdentifier: "NewImageViewController") as! NewImageViewController
        newImageViewController.delegate = self
        newCaptionViewController = storyBoard.instantiateViewController(withIdentifier: "NewCaptionViewController") as! NewCaptionViewController
        newHashTagViewController = storyBoard.instantiateViewController(withIdentifier: "NewHashTagViewController") as! NewHashTagViewController
        let vcList: [UIViewController] = [newHashTagViewController, newCaptionViewController, newImageViewController]
        self.pageMaster.setup(vcList)
        self.addChild(self.pageMaster)
        self.contentView.addSubview(self.pageMaster.view)
        self.pageMaster.view.frame = self.contentView.bounds
        self.pageMaster.didMove(toParent: self)
        self.pageMaster.setPage(2)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewMainPostCollectionViewCell", for: indexPath) as! NewMainPostCollectionViewCell
        
        if indexPath.row == 0 {
            cell.imageView.isHidden = true
            cell.numberLabel.isHidden = true
            cell.carmeraImageView.isHidden = false
            cell.selectedView.isHidden = true
        }else {
            cell.imageView.image = self.images[indexPath.row - 1]
            cell.imageView.isHidden = false
            cell.carmeraImageView.isHidden = true
            cell.numberLabel.layer.cornerRadius = 9.0
            cell.numberLabel.backgroundColor = .white
            cell.numberLabel.text = "\(indexPath.row)"
            cell.numberLabel.layer.masksToBounds = true
            if selectedImage != indexPath.row {
                cell.selectedView.isHidden = true
                cell.numberLabel.isHidden = true
            }else {
                cell.selectedView.isHidden = false
                cell.numberLabel.isHidden = false
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         print("Selected Cell: \(indexPath.row)")
        if indexPath.row == 0 {
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            vc.delegate = self
            present(vc, animated: true)
        }else {
            if (selectedImage == indexPath.row){
//                selectedImage = -1
            }else {
                selectedImage = indexPath.row
                self.fetchHighPhotoAtIndex(indexPath.row - 1)
                self.updateImage()
            }
            self.collectionView.reloadData()
        }
    }
    
    func fetchPhotos () {
        // Sort the images by descending creation date and fetch the first 3
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 60
        // Fetch the image assets
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        // If the fetch result isn't empty,
        // proceed with the image request
        if fetchResult.count > 0 {
            let totalImageCountNeeded = 60 // <-- The number of images to fetch
            fetchPhotoAtIndex(0, totalImageCountNeeded, fetchResult)
        }
    }

    // Repeatedly call the following method while incrementing
    // the index until all the photos are fetched
    func fetchPhotoAtIndex(_ index:Int, _ totalImageCountNeeded: Int, _ fetchResult: PHFetchResult<PHAsset>) {

        // Note that if the request is not set to synchronous
        // the requestImageForAsset will return both the image
        // and thumbnail; by setting synchronous to true it
        // will return just the thumbnail
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat

        // Perform the image request
        PHImageManager.default().requestImage(for: fetchResult.object(at: index) as PHAsset, targetSize: view.frame.size, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
            if let image = image {
                // Add the returned image to your array
                self.images += [image]
                if self.images.count == 1 {
                    self.fetchHighPhotoAtIndex(0)
                }
                self.collectionView.reloadData()
            }
            // If you haven't already reached the first
            // index of the fetch result and if you haven't
            // already stored all of the images you need,
            // perform the fetch request again with an
            // incremented index
            if index + 1 < fetchResult.count && self.images.count < totalImageCountNeeded {
                self.fetchPhotoAtIndex(index + 1, totalImageCountNeeded, fetchResult)
            } else {
                // Else you have completed creating your array
                print("Completed array: \(self.images)")
            }
        })
    }
    
    func fetchHighPhotoAtIndex(_ index:Int) {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat

        // Perform the image request
        PHImageManager.default().requestImage(for: fetchResult.object(at: index) as PHAsset, targetSize: view.frame.size, contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
            if let image = image {
                self.image = image
                self.updateImage()
            }
        })
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if pageMaster.currentPage < 2 {
            pageMaster.setPage(pageMaster.currentPage + 1, animated: true)
        }else {
            goNewPostViewController()
//            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func goNewPostViewController() {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "NewPostViewController") as! NewPostViewController
        if self.image == UIImage() {
            let alert = UIAlertController(title: "Please Choose Image", message: "You must choose the Image to add this post to.", preferredStyle: .alert)
                           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                           self.present(alert, animated: true, completion: nil)
            return
        }
        newPostViewController.imageToPost = self.image
        newPostViewController.imageAspectRatio = self.image.size.width / self.image.size.height
//        if  self.newCaptionViewController.captionString == "" {
//            let alert = UIAlertController(title: "Please input Caption", message: "You must input the Caption to add this post to.", preferredStyle: .alert)
//                           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                           self.present(alert, animated: true, completion: nil)
//            return
//        }
        newPostViewController.postCaption =
            self.newCaptionViewController.captionString
        newPostViewController.postCaptionBackGroundColorCode = self.newCaptionViewController.captionBGCode
        newPostViewController.postCaptionTextColorCode = self.newCaptionViewController.captionTextCode
//        if  self.newHashTagViewController.hashTagStings == [""] || self.newHashTagViewController.hashTagStings == [] {
//            let alert = UIAlertController(title: "Please set Hashtags", message: "You must choose the Hashtags or input new one to add this post to.", preferredStyle: .alert)
//                           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                           self.present(alert, animated: true, completion: nil)
//            return
//        }
        newPostViewController.postHashTags = self.newHashTagViewController.hashTagStings
        newPostViewController.newHashFlag = self.newHashTagViewController.newHashFlag
        newPostViewController.newHashTags = self.newHashTagViewController.newHashTagStrings

        API.User.observeCurrentUser { (currentUser) in            newPostViewController.postAuthor = currentUser
            newPostViewController.customTabBarController = self.customTabBarController
            newPostViewController.modalPresentationStyle = .fullScreen
            self.present(newPostViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func recentButtonPressed(_ sender: Any) {
        let pickerController = DKImagePickerController()
        pickerController.singleSelect = true
        pickerController.allowMultipleTypes = false
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            print("didSelectAssets")
            print(assets)
            for asset in assets {
                asset.fetchImage(with: UIScreen.main.bounds.size.toPixel(), completeBlock: { image, info in
                        self.image = image ?? UIImage()
                        self.updateImage()
                    self.selectedImage = -1
                    self.collectionView.reloadData()
                    }
                )
            }
        }
        self.present(pickerController, animated: true) {}
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        self.image = image
        self.updateImage()
        // print out the image size as a test
        print(image.size)
    }
    
    func updateImage() {
        print(self.image.size)
        newImageViewController.imageView.image = self.image
    }
    
    func gotoCaption() {
        self.pageMaster.setPage(1, animated: true)
    }
    
    func gotoHashTag() {
        self.pageMaster.setPage(0, animated: true)
    }
}

extension NewMainPostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - 6) / 4, height: (collectionView.frame.size.width - 6) / 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}
extension NewMainPostViewController: PageMasterDelegate, UIScrollViewDelegate {

    func pageMaster(_ master: PageMaster, didChangePage page: Int) {
        if page == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.newCaptionViewController.textView.becomeFirstResponder()
            }
        } else if page == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.newHashTagViewController.newHashText.becomeFirstResponder()
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
//        self.view.resignFirstResponder()
    }
}

extension NewMainPostViewController {
    
    func registerKeyboardNotifications() {

          NotificationCenter.default.addObserver(self, selector: #selector(NewMainPostViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        

          NotificationCenter.default.addObserver(self, selector: #selector(NewMainPostViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
      self.scrollView.frame.origin.y = 0 - keyboardSize.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.scrollView.frame.origin.y = 0
    }
}

