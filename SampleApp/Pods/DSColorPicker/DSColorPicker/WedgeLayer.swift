//
//  WedgeLayer.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-26.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import UIKit

final class WedgeLayer: CALayer {
    
    // MARK: - Properties

    @NSManaged var startAngle: CGFloat
    @NSManaged var endAngle: CGFloat
    @NSManaged var radius: CGFloat
    @NSManaged var color: CGColor
    
    // MARK: - Initialization
    
    init(color: CGColor, radius: CGFloat, startAngle: CGFloat = 0, endAngle: CGFloat = CGFloat.pi * 2) {
        super.init()
        self.color = color
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
    }
    
    // Needed to implement this in order to access the presentation layer for the custom animation... without this there is a runtime expection in draw
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hit Testing
    
    // The hit is successful if the point lies in the drawn circle segment
    override func hitTest(_ p: CGPoint) -> CALayer? {
        // convert to our coordinate system
        let pt = convert(p, from: superlayer)
        for lay in sublayers ?? [] {
            if let hit = lay.hitTest(pt) {
                return hit
            }
        }
        
        guard (pt.x - bounds.center.x) * (pt.x - bounds.center.x)
            + (pt.y - bounds.center.y) * (pt.y - bounds.center.y)
            <= radius * radius else {
            return nil
        }
        
        let x = p.x - bounds.center.x
        let y = p.y - bounds.center.y
        
        guard x != 0 else {
            return nil
        }
        
        // atan provides a value between -pi / 2 and pi / 2
        // we will map it to between 0 and 2 pi
        var theta = atan(y / x)
        
        // bottom right quadrant
        if x < 0 && y >= 0 {
            theta += CGFloat.pi
        }
        
        // top left quadrant
        if x < 0 && y < 0 {
            theta += CGFloat.pi
        }
        
        // top right quadrant
        if x > 0 && y < 0 {
            theta += CGFloat.pi * 2
        }
        
        // map the start and end angle to values between 0 and 2 pi
        var start: CGFloat = startAngle.truncatingRemainder(dividingBy: CGFloat.pi * 2)
        var end: CGFloat = endAngle.truncatingRemainder(dividingBy: CGFloat.pi * 2)
        
        if start < 0 {
            start += CGFloat.pi * 2
        }
        
        if end < 0 {
            end += CGFloat.pi * 2
        }
        
        // special case when the end angle wraps around the origin
        if end < start {
            end += CGFloat.pi * 2
        }
        
        // special case when we have a full circle
        if end == start {
            end = start + CGFloat.pi * 2
        }
        
        // the angle formed by the line segment joining the center of the segment to the point
        // must be between the start and the end angle of the segment
        guard start <= theta && theta <= end else {
            return nil
        }
        
        return self
    }
    
    // MARK: - Animations
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(startAngle)
            || key == #keyPath(endAngle)
            || key == #keyPath(color)
            || key == #keyPath(radius)  {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    override func action(forKey event: String) -> CAAction? {
        if event == #keyPath(startAngle) {
            let anim = CABasicAnimation(keyPath: event)
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            anim.fromValue = startAngle
            return anim
        }
        
        if event == #keyPath(endAngle) {
            let anim = CABasicAnimation(keyPath: event)
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            anim.fromValue = endAngle
            return anim
        }
        
        if event == #keyPath(radius) {
            let anim = CABasicAnimation(keyPath: event)
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            anim.fromValue = radius
            return anim
        }
        
        return super.action(forKey: event)
    }
    
    // MARK: - Drawing
    
    override func draw(in ctx: CGContext) {
        let start = presentation()?.startAngle ?? self.startAngle
        let end = presentation()?.endAngle ?? self.endAngle
        let radius = presentation()?.radius ?? self.radius
        let center = CGPoint(x: (presentation()?.bounds.width ?? bounds.width) / 2, y: (presentation()?.bounds.height ?? bounds.height) / 2)
        
        ctx.move(to: center)
        ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        ctx.closePath()
        // color
        ctx.setFillColor(color)
        ctx.setStrokeColor(color)
        ctx.drawPath(using: .fillStroke)
    }
}
