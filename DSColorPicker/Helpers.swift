//
//  Helpers.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-12.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: minX + width / 2, y: minY + height / 2)
    }
}

extension CGPoint {
    func distanceFrom(point: CGPoint) -> CGFloat {
        return CGFloat(sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y)))
    }
}

extension UIBezierPath {
    func fillAndStroke() {
        self.fill()
        self.stroke()
    }
}
