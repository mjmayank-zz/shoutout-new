//
//  UIView+CornerRadius.swift
//  shoutout
//
//  Created by Mayank Jain on 3/23/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import Foundation

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

}

@IBDesignable
class CircularView: UIView {
    @IBInspectable var circluarView: Bool{
        get{
            return frame.height == frame.width && layer.cornerRadius == frame.height/2.0
        }
        set{
            layer.cornerRadius = frame.width/2.0
            layer.masksToBounds = newValue
        }
    }
}