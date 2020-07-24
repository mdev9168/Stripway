//
//  Extensions.swift
//  Stripway
//
//  Created by iOS Dev on 2/12/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import Foundation
import UIKit

extension Array {
    mutating func rotate(positions: Int, size: Int? = nil) {
        guard positions < count && (size ?? 0) <= count else {
            print("invalid input1")
            return
        }
        reversed(start: 0, end: positions - 1)
        reversed(start: positions, end: (size ?? count) - 1)
        reversed(start: 0, end: (size ?? count) - 1)
    }
    mutating func reversed(start: Int, end: Int) {
        guard start >= 0 && end < count && start < end else {
            return
        }
        var start = start
        var end = end
        while start < end, start != end {
            self.swapAt(start, end)
            start += 1
            end -= 1
        }
    }
}

//MARK:- UICOLOR EXTENSTION
extension UIColor {
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

//HASH TAG
struct PrefixesDetected {
   let text: String
   let prefix: String?
}
extension String {
    
        func trimNewLine() -> String {
              return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    
    func getHasTagPrefixesObjArr(_ prefixes: [String] = ["#", "@"]) -> [PrefixesDetected] {

        let words = self.components(separatedBy: " ")

        return words.map { word -> PrefixesDetected in
            PrefixesDetected(text: word,
                             prefix: word.hasPrefix(prefixes: prefixes))
        }
    }

    func hasPrefix(prefixes: [String]) -> String? {
        for prefix in prefixes {
            if hasPrefix(prefix) {
                return prefix
            }
        }
        return nil
    }
    var trimWhiteSpace: String {
        let trimmedString = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        return trimmedString
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
