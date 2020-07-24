//
//  NewCaptionViewController.swift
//  Stripway
//
//  Created by Troy on 5/2/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit

class NewCaptionViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textView: MyTextView!
    
    var captionString = ""
    var captionBGCode = "#000000"
    var captionTextCode = "#FFFFFF"
    var colorFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.alignTextVerticallyInContainer()
        registerKeyboardNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        textView.alignTextVerticallyInContainer()
    } 

    
    @IBAction func chooseBlack(_ sender: Any) {
        self.backgroundView.backgroundColor = UIColor.black
        self.textView.textColor = UIColor.white
        self.textView.tintColor = UIColor.white
        colorFlag = false
//        self.view.endEditing(true)
    }
    
    @IBAction func chooseWhite(_ sender: Any) {
        self.backgroundView.backgroundColor = UIColor.white
        self.textView.textColor = UIColor.black
        self.textView.tintColor = UIColor.black
        colorFlag = true
//        self.view.endEditing(true)
    }

}

extension NewCaptionViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if colorFlag
        {
            self.textView.tintColor = UIColor.black
            self.captionBGCode = "#FFFFFF"
            self.captionTextCode = "#000000"
        }else{
            self.textView.tintColor = UIColor.white
            self.captionBGCode = "#000000"
            self.captionTextCode = "#FFFFFF"
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        if colorFlag
        {
            self.textView.tintColor = UIColor.black
        }else{
            self.textView.tintColor = UIColor.white
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if colorFlag
        {
            self.textView.tintColor = UIColor.black
        }else{
            self.textView.tintColor = UIColor.white
        }
        if textView.text.count == 0 {
            textView.text = "Say Something..."
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
             
        let maxLength = 364
        let currentString: NSString = textView.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: text) as NSString
        
        if colorFlag
        {
            self.textView.tintColor = UIColor.black
            self.captionBGCode = "#FFFFFF"
            self.captionTextCode = "#000000"
        }else{
            self.textView.tintColor = UIColor.white
            self.captionBGCode = "#000000"
            self.captionTextCode = "#FFFFFF"
        }
        
        if let text1 = textView.text, let swiftRange = Range(range, in: text1) {
           self.captionString = text1.replacingCharacters(in: swiftRange, with: text)
        } else {
           self.captionString = text
        }
        
        if textView.text == "Say Something..."
        {
            textView.text = ""
            self.captionString = text
        }
        
        textView.alignTextVerticallyInContainer()
        print(self.captionString)
        return newString.length <= maxLength
    }
}

class MyTextView: UITextView {

    override func caretRect(for position: UITextPosition) -> CGRect {
        var superRect = super.caretRect(for: position)
        guard let font = self.font else { return superRect }

        superRect.size.height = font.pointSize - font.descender
        return superRect
    }
}

extension UITextView {
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    
    func alignTextVerticallyInContainer() {
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        self.contentInset.top = topCorrect
    }
}

extension NewCaptionViewController {

    func registerKeyboardNotifications() {

          NotificationCenter.default.addObserver(self, selector: #selector(NewCaptionViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)


          NotificationCenter.default.addObserver(self, selector: #selector(NewCaptionViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {

        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
        
        let bounds = UIScreen.main.bounds
        let height = bounds.size.height
        let frm: CGRect = backgroundView.frame

        let y = frm.origin.y + frm.size.height


      // move the root view up by the distance of keyboard height
        self.textView.frame.origin.y = 0 - (keyboardSize.height - height + y + 64.0)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.textView.frame.origin.y = 0
    }
}
