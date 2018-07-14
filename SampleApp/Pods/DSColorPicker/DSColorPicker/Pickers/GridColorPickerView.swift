//
//  GridColorPickerView.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-04.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import UIKit

public final class GridColorPickerView: UIView, GridColorPickerViewType {
    
    private struct CircleProperties {
        let color: CGColor
        let radius: CGFloat
        let position: CGPoint
        init(color: CGColor, radius: CGFloat, position: CGPoint) {
            self.color = color
            self.radius = radius
            self.position = position
        }
    }
    
    // MARK: - Properties
    
    private let defaultNumberOfColors: Int                                  = 16
    private let defaultMaxNumberOfColorsPerRow: Int                         = 4
    private let defaultMaxNumberOfColorsPerColumn: Int                      = 4
    private let defaultPaddingLeft: CGFloat                                 = 10
    private let defaultPaddingRight: CGFloat                                = 10
    private let defaultPaddingTop: CGFloat                                  = 10
    private let defaultPaddingBottom: CGFloat                               = 10
    private let defaultPaddingBetweenRows: CGFloat                          = 15
    private let defaultPaddingBetweenColumns: CGFloat                       = 15
    private let wedgeScaleRadiusFactor: CGFloat                             = 1.1
    private let showAnimationDuration: CFTimeInterval                       = 1.0
    private let wedgeScaleUpRadiusDuration: CFTimeInterval                  = 0.1
    private let wedgeScaleDownRadiusDuration: CFTimeInterval                = 0.1
    private let reloadPickerAnimationDuration: CFTimeInterval               = 0.5
    private let reloadPickerAnimationTimingFunctionName: String             = kCAMediaTimingFunctionEaseInEaseOut
    
    private var restoredLastWedgeTouched: Bool = true
    private var isTouchingAWedge: Bool = false
    
    weak public var dataSource: GridColorPickerViewDataSource?
    weak public var delegate: ColorPickerViewDelegate?
    
    private var selectedColor: UIColor {
        didSet {
            if selectedColor != oldValue {
                delegate?.didSelect(color: selectedColor, pickerView: self)
            }
        }
    }
    
    private var selectedWedge: WedgeLayer = WedgeLayer(color: UIColor.black.cgColor, radius: 0) {
        didSet {
            selectedColor = UIColor(cgColor: selectedWedge.color)
        }
    }
    
    private lazy var circles: [WedgeLayer] = {
        var circles = [WedgeLayer]()
        for i in 0..<(dataSource?.numberOfColors ?? defaultNumberOfColors) {
            let circle = WedgeLayer(color: UIColor.black.cgColor, radius: 0, startAngle: 0, endAngle: CGFloat.pi * 2)
            circle.transform = CATransform3DMakeScale(0.0, 0.0, 1.0)
            circles.append(circle)
        }
        return circles
    }()
    
    // MARK: - Initialization
    
    public init(frame: CGRect, delegate: ColorPickerViewDelegate, dataSource: GridColorPickerViewDataSource) {
        self.selectedColor = UIColor.black
        self.delegate = delegate
        self.dataSource = dataSource
        super.init(frame: frame)
        
        // Disable the pesky implicit animation of the endAngle
        CATransaction.setDisableActions(true)
        for circle in circles {
            self.layer.addSublayer(circle)
        }
        CATransaction.setDisableActions(false)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    // Returns the appropriate properties of the wedge layer for a given index
    private func propertiesForCircle(withIndex idx: Int, insideRect rect: CGRect, andTotalNumberOfCircles numberOfCircles: Int) -> CircleProperties {
        let numColors = numberOfCircles
        let maxWidth = dataSource?.maxColumns ?? 4
        
        let width = numColors < maxWidth ? numColors : maxWidth
        let height = Int(ceil(CGFloat(numColors) / CGFloat(maxWidth)))
        
        let row: Int = idx / width
        let col: Int = idx % width
        
        let rowSpaceForCircles = self.layer.bounds.width - defaultPaddingLeft - defaultPaddingRight - CGFloat(width - 1) * defaultPaddingBetweenColumns
        let colSpaceForCircles = self.layer.bounds.height - defaultPaddingTop - defaultPaddingBottom - CGFloat(height - 1) * defaultPaddingBetweenRows
        let radius = min(colSpaceForCircles / CGFloat(height), rowSpaceForCircles / CGFloat(width)) / 2.0
        
        let totalPaddingTop = (self.layer.bounds.height
            - defaultPaddingTop
            - defaultPaddingBottom
            - CGFloat(height) * radius * 2
            - CGFloat(height - 1) * defaultPaddingBetweenRows)
            / 2.0
            + defaultPaddingTop
        
        let totalPaddingLeft: CGFloat
        
        // Vertically center the last row
        if row == height - 1 && numColors % maxWidth != 0 {
            let numberOfCirclesInRow = numColors % maxWidth
            totalPaddingLeft = (self.layer.bounds.width - defaultPaddingLeft - defaultPaddingRight - CGFloat(numberOfCirclesInRow) * radius * 2 - CGFloat(numberOfCirclesInRow - 1) * defaultPaddingBetweenColumns) / 2.0 + defaultPaddingLeft
        } else {
            totalPaddingLeft = (self.layer.bounds.width - defaultPaddingLeft - defaultPaddingRight - CGFloat(width) * radius * 2 - CGFloat(width - 1) * defaultPaddingBetweenColumns) / 2.0 + defaultPaddingLeft
        }

        let color = dataSource?.color(at: idx) ?? UIColor.black.cgColor
        let position = CGPoint(x: totalPaddingLeft + CGFloat(col) * (radius * 2 + defaultPaddingBetweenColumns) + radius,
                               y: totalPaddingTop + CGFloat(row) * (radius * 2 + defaultPaddingBetweenRows) + radius)
        return CircleProperties(color: color, radius: radius, position: position)
    }
    
    override public func layoutSublayers(of layer: CALayer) {
        let numCircles = dataSource?.numberOfColors ?? defaultNumberOfColors
        for i in 0..<numCircles {
            guard i < circles.count else {
                break
            }
            let circleProperties = propertiesForCircle(withIndex: i, insideRect: self.layer.bounds, andTotalNumberOfCircles: numCircles)
            circles[i].color = circleProperties.color
            circles[i].position = circleProperties.position
            circles[i].bounds = self.layer.bounds
            circles[i].radius = circleProperties.radius - 1
        }
    }

    // MARK: - Animations
    
    /// The animation involves:
    /// 1. Translating circles to their new position.
    /// 2. Changing the color for each circle from the color associated with its old index to the color associated with its new index.
    /// 3. Shrinking circles that need to be removed to a single point and then removing them from the layer.
    ///
    public func reloadPicker(animated: Bool = true, completion: @escaping () -> (Void) = {}) {
        let oldNumCircles = circles.count
        let newNumCircles = dataSource?.numberOfColors ?? defaultNumberOfColors
        
        guard oldNumCircles != newNumCircles else {
            completion()
            return
        }
        
        isUserInteractionEnabled = false
        
        CATransaction.setDisableActions(true)
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.isUserInteractionEnabled = true
            completion()
        }
        
        if newNumCircles > oldNumCircles {
            for i in 0..<(newNumCircles - oldNumCircles) {
                let circleProperties = propertiesForCircle(withIndex: oldNumCircles + i, insideRect: self.layer.bounds, andTotalNumberOfCircles: newNumCircles)
                let circle = WedgeLayer(color: UIColor.black.cgColor, radius: 0, startAngle: 0, endAngle: CGFloat.pi * 2)
                circle.color = circleProperties.color
                circle.position = circleProperties.position
                circle.bounds = CGRect(x: 0, y: 0, width: (circleProperties.radius * 2) * wedgeScaleRadiusFactor, height: (circleProperties.radius * 2) * wedgeScaleRadiusFactor)
                self.layer.addSublayer(circle)
                
                // Use a scale up animation instead of animating the radius because the radius animation isn't smooth enough
                let scaleX = CABasicAnimation(keyPath: "transform.scale.x")
                let scaleY = CABasicAnimation(keyPath: "transform.scale.y")
                let group = CAAnimationGroup()
                scaleX.fromValue = 0.0
                scaleX.toValue = 1.0
                scaleY.fromValue = 0.0
                scaleY.toValue = 1.0
                group.animations = [scaleX, scaleY]
                group.duration = reloadPickerAnimationDuration
                group.timingFunction = CAMediaTimingFunction(name: reloadPickerAnimationTimingFunctionName)
                circle.add(group, forKey: nil)
                
                circles.append(circle)
            }
        }
        // Need to remove circles if the total number decreases
        if newNumCircles < oldNumCircles {
            var i = circles.count - 1
            for _ in 0..<(oldNumCircles - newNumCircles) {
                let circle = circles[i]
                circle.transform = CATransform3DMakeScale(0.0, 0.0, 1.0)
                
                CATransaction.begin()
                CATransaction.setCompletionBlock {
                    circle.removeFromSuperlayer()
                }
                let scaleX = CABasicAnimation(keyPath: "transform.scale.x")
                let scaleY = CABasicAnimation(keyPath: "transform.scale.y")
                let group = CAAnimationGroup()
                scaleX.fromValue = 1.0
                scaleX.toValue = 0.0
                scaleY.fromValue = 1.0
                scaleY.toValue = 0.0
                group.animations = [scaleX, scaleY]
                group.duration = reloadPickerAnimationDuration
                group.timingFunction = CAMediaTimingFunction(name: reloadPickerAnimationTimingFunctionName)
                circle.add(group, forKey: nil)
                CATransaction.commit()
                
                circles.remove(at: i)
                i -= 1
            }
        }
        
        for (idx, circle) in circles.enumerated() {
            let circleProperties = propertiesForCircle(withIndex: idx, insideRect: self.layer.bounds, andTotalNumberOfCircles: newNumCircles)
            
            let colorAnim = CABasicAnimation(keyPath: "color")
            let positionAnim = CABasicAnimation(keyPath: "position")
            let radiusAnim = CABasicAnimation(keyPath: "radius")
            let groupAnim = CAAnimationGroup()
            
            colorAnim.fromValue = circle.color
            positionAnim.fromValue = circle.position
            radiusAnim.fromValue = circle.radius
            
            colorAnim.toValue = circleProperties.color
            positionAnim.toValue = circleProperties.position
            radiusAnim.toValue = circleProperties.radius - 1
            
            groupAnim.duration = reloadPickerAnimationDuration
            groupAnim.animations = [colorAnim, positionAnim, radiusAnim]
            groupAnim.timingFunction = CAMediaTimingFunction(name: reloadPickerAnimationTimingFunctionName)
            
            circle.add(groupAnim, forKey: nil)
            // Don't need to configure the circles properties because layoutSublayers gets called
        }
        
        CATransaction.setDisableActions(false)
        CATransaction.commit()
    }
    
    /// A spring animation that expands the circles from a single point to their expected size about their respective centers.
    ///
    public func show(animated: Bool = true, completion: @escaping () -> (Void) = {}) {
        isUserInteractionEnabled = false
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { [weak self] in
            self?.isUserInteractionEnabled = true
            completion()
        }
        for circle in circles {
            if animated {
                let scaleX = CASpringAnimation(keyPath: "transform.scale.x")
                let scaleY = CASpringAnimation(keyPath: "transform.scale.y")
                scaleX.fromValue = 0
                scaleY.fromValue = 0
                scaleX.toValue = 1
                scaleY.toValue = 1
                scaleX.duration = showAnimationDuration
                scaleY.duration = showAnimationDuration
                circle.add(scaleX, forKey: nil)
                circle.add(scaleY, forKey: nil)
            }
            circle.transform = CATransform3DIdentity
        }
        CATransaction.setDisableActions(false)
        CATransaction.commit()
    }
    
    private func animateWedgeRadius(wedge: WedgeLayer, to radius: CGFloat, duration: CFTimeInterval) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let anim = CABasicAnimation(keyPath: "radius")
        anim.fromValue = wedge.radius
        anim.toValue = radius
        anim.duration = duration
        wedge.add(anim, forKey: nil)
        wedge.radius = radius
        CATransaction.setDisableActions(false)
        CATransaction.commit()
    }
    
    // MARK: - Touch
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else {
            return
        }
        
        if let wedge = layer.hitTest(layer.convert(p, to: layer.superlayer)) as? WedgeLayer {
            isTouchingAWedge = true
            restoredLastWedgeTouched = false
            animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
            selectedWedge = wedge
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else {
            return
        }
        
        // Cases to consider
        // 1. wedge -> different wedge
        // 2. wedge -> same wedge
        // 3. wedge -> no wedge
        // 4. no wedge -> wedge
        // 5. no wedge -> no wedge
        if let wedge = layer.hitTest(layer.convert(p, to: layer.superlayer)) as? WedgeLayer {
            if isTouchingAWedge {
                // wedge -> different wedge
                if selectedWedge != wedge {
                    animateWedgeRadius(wedge: selectedWedge, to: selectedWedge.radius / wedgeScaleRadiusFactor, duration: wedgeScaleDownRadiusDuration)
                    animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
                    selectedWedge = wedge
                }
                // wedge -> same wedge
                else {
                    
                }
            }
            // no wedge -> wedge
            else {
                isTouchingAWedge = true
                restoredLastWedgeTouched = false
                animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
                selectedWedge = wedge
            }
        }
        else {
            // wedge -> no wedge
            if !restoredLastWedgeTouched {
                animateWedgeRadius(wedge: selectedWedge, to: selectedWedge.radius / wedgeScaleRadiusFactor, duration: wedgeScaleDownRadiusDuration)
                restoredLastWedgeTouched = true
                isTouchingAWedge = false
            }
            // no wedge -> no wedge
            else {
               
            }
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTouchingAWedge {
            animateWedgeRadius(wedge: selectedWedge, to: selectedWedge.radius / wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
            restoredLastWedgeTouched = true
            isTouchingAWedge = false
        }
    }
}
