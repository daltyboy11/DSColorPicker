//
//  CircleColorPickerView.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-04.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import UIKit

public final class CircleColorPickerView: UIView, DSCircleColorPickerViewType {
    
    // MARK: - Properties
    
    private let wedgeShowScaleDuration: CFTimeInterval              = 0.95
    private let wedgeShowRotateDuration: CFTimeInterval             = 0.6
    private let wedgeScaleUpRadiusDuration: CFTimeInterval          = 0.1
    private let wedgeScaleDownRadiusDuration: CFTimeInterval        = 0.1
    private let reloadPickerAnimationDuration: CFTimeInterval       = 0.5
    private let reloadPickerAnimationTimingFunctionName: String     = kCAMediaTimingFunctionEaseInEaseOut
    private let wedgeScaleRadiusFactor: CGFloat                     = 1.1
    private let circlePadding: CGFloat                              = 10
    
    weak public var dataSource: DSColorPickerViewDataSource?
    weak public var delegate: DSColorPickerViewDelegate?
    
    private var isTouchingInCircle: Bool = false
    private var animatedLastWedgeTouched: Bool = true
    
    private var selectedWedge: WedgeLayer = WedgeLayer(color: UIColor.black.cgColor, radius: 0) {
        didSet {
            selectedColor = UIColor(cgColor: selectedWedge.color)
        }
    }
    
    private var circleCenter: CGPoint {
        return CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    private var circleRadius: CGFloat {
        return min(bounds.width, bounds.height) / 2 - circlePadding
    }
    
    private var selectedColor: UIColor {
        didSet {
            if selectedColor != oldValue {
                delegate?.didSelect(color: selectedColor, pickerView: self)
            }
        }
    }
    
    // Make the collection of circle wedges a lazy property so they can be configured after the layers bounds/position have been configured.
    private lazy var wedges: [WedgeLayer] = {
        var layers = [WedgeLayer]()
        let numWedges = dataSource?.numberOfColors ?? 15
        let increment = 2 * CGFloat.pi / CGFloat(numWedges)
        for i in 0..<numWedges {
            let color = dataSource?.color(at: i) ?? UIColor.black.cgColor
            let wedgeLayer = WedgeLayer(color: color, radius: circleRadius, startAngle: 0, endAngle: 0)
            wedgeLayer.bounds = layer.bounds
            wedgeLayer.position = layer.bounds.center
            // transform the layer to prepare it for presentation
            wedgeLayer.transform = CATransform3DMakeScale(0, 0, 1)
            layers.append(wedgeLayer)
        }
        return layers
    }()
    
    // MARK: - Initializers
    
    public init(frame: CGRect, delegate: DSColorPickerViewDelegate, dataSource: DSColorPickerViewDataSource) {
        self.selectedColor = UIColor.black
        self.delegate = delegate
        self.dataSource = dataSource
        super.init(frame: frame)
        for wedgeLayer in wedges {
            layer.addSublayer(wedgeLayer)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override public func layoutSublayers(of layer: CALayer) {
        for wedge in wedges {
            wedge.bounds = self.bounds
            wedge.position = self.bounds.center
            wedge.radius = circleRadius
            wedge.setNeedsDisplay()
        }
    }
    
    // MARK: - Touches
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let p = touches.first?.location(in: self) {
            if let wedge = layer.hitTest(layer.convert(p, to: layer.superlayer)) as? WedgeLayer {
                isTouchingInCircle = true
                animatedLastWedgeTouched = false
                selectedWedge = wedge
                animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
            }
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else {
            return
        }
        
        if let wedge = layer.hitTest(layer.convert(p, to: layer.superlayer)) as? WedgeLayer {
            // moving into the circle
            if !isTouchingInCircle {
                isTouchingInCircle = true
                animatedLastWedgeTouched = false
                animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
            }
            // moving within the circle
            else if isTouchingInCircle {
                if wedge != selectedWedge {
                    animateWedgeRadius(wedge: selectedWedge, to: circleRadius, duration: wedgeScaleDownRadiusDuration)
                    animateWedgeRadius(wedge: wedge, to: wedge.radius * wedgeScaleRadiusFactor, duration: wedgeScaleUpRadiusDuration)
                    selectedWedge = wedge
                }
            }
        }
        // moving out of the circle
        else {
            isTouchingInCircle = false
            if !animatedLastWedgeTouched {
                animateWedgeRadius(wedge: selectedWedge, to: circleRadius, duration: wedgeScaleDownRadiusDuration)
                animatedLastWedgeTouched = true
            }
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTouchingInCircle {
            isTouchingInCircle = false
            animateWedgeRadius(wedge: selectedWedge, to: circleRadius, duration: wedgeScaleDownRadiusDuration)
        }
    }
    
    // MARK: - Animation
    
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
    
    /// The animation involves:
    /// 1. Shrinking un-needed wedges by decreasing their fraction of the circles until the fraction is 0.0.
    /// 2. Expanding new wedges from a fraction of 0.0 to the expected fraction.
    /// 3. Changing the color of each wedge from the color associated with its old index to the color associated with its new index.
    ///
    public func reloadPicker(animated: Bool = true, completion: @escaping () -> (Void) = {}) {
        let oldNumWedges = wedges.count
        let newNumWedges = dataSource?.numberOfColors ?? 15
        let increment = 2 * CGFloat.pi / CGFloat(newNumWedges)
        
        self.isUserInteractionEnabled = false
        if newNumWedges > oldNumWedges {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setCompletionBlock { [weak self] in
                print("completed reload 1")
                self?.isUserInteractionEnabled = true
                completion()
            }
            for i in 0..<(newNumWedges - oldNumWedges) {
                let color = dataSource?.color(at: i) ?? UIColor.black.cgColor
                let wedge = WedgeLayer(color: color, radius: circleRadius, startAngle: 0, endAngle: 0)
                wedge.bounds = self.layer.bounds
                wedge.position = self.layer.position
                self.layer.addSublayer(wedge)
                wedges.insert(wedge, at: i)
            }
            for i in 0..<newNumWedges {
                let start = CGFloat(i) * increment
                let end = CGFloat(i + 1) * increment
                let color = dataSource?.color(at: i) ?? UIColor.black.cgColor
                
                // TODO: - Need to figure out why I need this... don't understand why the order in which the wedge's properties are configured and the animations are configured affects the behavior of the animation.
                if !animated {
                    wedges[i].color = color
                    wedges[i].startAngle = start
                    wedges[i].endAngle = end
                }
                
                let colorAnim = CABasicAnimation(keyPath: "color")
                let startAngleAnim = CABasicAnimation(keyPath: "startAngle")
                let endAngleAnim = CABasicAnimation(keyPath: "endAngle")
                let group = CAAnimationGroup()
                group.animations = [colorAnim, startAngleAnim, endAngleAnim]
                
                group.duration = animated ? self.reloadPickerAnimationDuration : 0
                
                colorAnim.fromValue = wedges[i].color
                startAngleAnim.fromValue = wedges[i].startAngle
                endAngleAnim.fromValue = wedges[i].endAngle
                
                startAngleAnim.toValue = start
                endAngleAnim.toValue = end
                colorAnim.toValue = color
                
                startAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                endAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                colorAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                
                if animated {
                    wedges[i].color = color
                    wedges[i].startAngle = start
                    wedges[i].endAngle = end
                }
                
                wedges[i].add(group, forKey: nil)
            }
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
        else if newNumWedges < oldNumWedges {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            CATransaction.setCompletionBlock { [weak self] in
                print("complete reload 2")
                self?.isUserInteractionEnabled = true
                completion()
            }
            for i in stride(from: wedges.count - 1, to: -1, by: -1) {
                let start = CGFloat(i) * increment
                let end = CGFloat(i + 1) * increment
                let color = dataSource?.color(at: i) ?? UIColor.black.cgColor
                if i >= newNumWedges {
                    let wedge = wedges[i]
                    CATransaction.begin()
                    CATransaction.setCompletionBlock {
                        print("removing wedge from superlayer")
                        wedge.removeFromSuperlayer()
                    }
                    if animated {
                        // Put the disappearing wedge behind any expanding wedges
                        wedge.zPosition = -1
                        
                        let startAngleAnim = CABasicAnimation(keyPath: "startAngle")
                        let endAngleAnim = CABasicAnimation(keyPath: "endAngle")
                        let group = CAAnimationGroup()
                        
                        group.animations = [startAngleAnim, endAngleAnim]
                        group.duration = self.reloadPickerAnimationDuration
                        
                        startAngleAnim.fromValue = wedge.startAngle
                        endAngleAnim.fromValue = wedge.endAngle
                        
                        startAngleAnim.toValue = CGFloat.pi * 2
                        endAngleAnim.toValue = CGFloat.pi * 2
                        
                        startAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                        endAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                        
                        wedge.add(group, forKey: nil)
                    }
                    wedges.remove(at: i)
                    CATransaction.commit()
                } else {
                    if animated {
                        let colorAnim = CABasicAnimation(keyPath: "color")
                        let startAngleAnim = CABasicAnimation(keyPath: "startAngle")
                        let endAngleAnim = CABasicAnimation(keyPath: "endAngle")
                        let group = CAAnimationGroup()
                        
                        group.animations = [colorAnim, startAngleAnim, endAngleAnim]
                        group.duration = self.reloadPickerAnimationDuration
                        
                        colorAnim.fromValue = wedges[i].color
                        startAngleAnim.fromValue = wedges[i].startAngle
                        endAngleAnim.fromValue = wedges[i].endAngle
                        
                        startAngleAnim.toValue = start
                        endAngleAnim.toValue = end
                        colorAnim.toValue = color
                        
                        startAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                        endAngleAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                        colorAnim.timingFunction = CAMediaTimingFunction(name: self.reloadPickerAnimationTimingFunctionName)
                        
                        wedges[i].add(group, forKey: nil)
                    }
                    
                    wedges[i].color = color
                    wedges[i].startAngle = start
                    wedges[i].endAngle = end
                }
            }
            CATransaction.commit()
            CATransaction.setDisableActions(false)
        }
    }
    
    /// The animation involves:
    /// 1. Expanding the circle out from the center.
    /// 2. "Fanning" the wedges out, going clockwise.
    ///
    public func show(animated: Bool = true, completion: @escaping () -> (Void) = {}) {
        isUserInteractionEnabled = false
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { [weak self] in
            self?.isUserInteractionEnabled = true
            completion()
        }
        let increment = 2 * CGFloat.pi / CGFloat(wedges.count)
        for (idx, wedge) in wedges.enumerated() {
            let startAngle = CGFloat(idx) * increment
            let endAngle = CGFloat(idx + 1) * increment
            
            wedge.transform = CATransform3DIdentity
            wedge.startAngle = startAngle
            wedge.endAngle = endAngle
            
            if animated {
                let scaleXAnim = CASpringAnimation(keyPath: "transform.scale.x")
                let scaleYAnim = CASpringAnimation(keyPath: "transform.scale.y")
                let startAngleAnim = CABasicAnimation(keyPath: "startAngle")
                let endAngleAnim = CABasicAnimation(keyPath: "endAngle")
                let groupAnim = CAAnimationGroup()
                groupAnim.animations = [scaleXAnim, scaleYAnim, startAngleAnim, endAngleAnim]
                
                scaleXAnim.fromValue = 0
                scaleYAnim.fromValue = 0
                startAngleAnim.fromValue = 0
                endAngleAnim.fromValue = 0
                
                startAngleAnim.toValue = startAngle
                endAngleAnim.toValue = endAngle
                scaleXAnim.toValue = 1.0
                scaleYAnim.toValue = 1.0
                
                scaleXAnim.duration = self.wedgeShowScaleDuration
                scaleYAnim.duration = self.wedgeShowScaleDuration
                startAngleAnim.duration = self.wedgeShowRotateDuration
                endAngleAnim.duration = self.wedgeShowRotateDuration
                groupAnim.duration = max(self.wedgeShowScaleDuration, self.wedgeShowRotateDuration)
                
                wedge.add(groupAnim, forKey: nil)
            }
        }
        CATransaction.commit()
        CATransaction.setDisableActions(false)
    }
}
