//
//  ColorPickerViewType.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-04.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import Foundation
import UIKit

public protocol DSColorPickerViewType {
    /// The picker's delegate object. Use this object to handle user interaction with the color picker.
    ///
    var delegate: DSColorPickerViewDelegate? { get set }
    
    /// Call this method when you are ready to show the picker.
    ///
    /// - parameter animated: If true, the picker will present itself with animation. Otherwise, it will present itself with no animation.
    ///
    /// - parameter completion: Handler called after the picker is shown.
    ///
    func show(animated: Bool, completion: @escaping () -> (Void))
    
    /// Call this method to reload the picker based on updates to its datasource. For example, call this method after changing the number of colors or the colors for specific indices.
    ///
    /// - parameter animated: If true, the picker will reload itself with animation. Otherwise, it will reload itself with no animation.
    /// - parameter completion: Handler called after the picker is reloaded.
    ///
    func reloadPicker(animated: Bool, completion: @escaping () -> (Void))
}

public protocol DSGridColorPickerViewType: DSColorPickerViewType {
    var dataSource: DSGridColorPickerViewDataSource? { get set }
}

public protocol DSCircleColorPickerViewType: DSColorPickerViewType {
    var dataSource: DSColorPickerViewDataSource? { get set }
}
