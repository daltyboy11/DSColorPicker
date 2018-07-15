//
//  ColorPickerViewDataSource.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-04.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import Foundation
import CoreGraphics.CGColor

/// Adopt this protocol to be a data source object for a CircleColorPickerView
///
public protocol DSColorPickerViewDataSource: AnyObject {
    /// The number of colors to be displayed by the view.
    ///
    var numberOfColors: Int { get }
    
    /// The color at the specified index
    ///
    func color(at index: Int) -> CGColor
}
