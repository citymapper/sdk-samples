//
//  UILabel+Layouting.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 19/03/2021.
//

import UIKit

extension UILabel {
    func attributedTextHeight(withWidth width: CGFloat) -> CGFloat {
        guard let attributedText = attributedText else {
            return 0
        }
        return attributedText.height(withWidth: width)
    }
}

extension NSAttributedString {
    func height(withWidth width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let context = NSStringDrawingContext()
        let actualSize = boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], context: context)
        return actualSize.height
    }
}
