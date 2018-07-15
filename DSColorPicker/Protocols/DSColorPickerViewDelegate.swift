//
//  ColorPickerViewDelegate.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-06-04.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import Foundation
import UIKit

/// Adopt this protocol to be a delegate object for a color picker
///
public protocol DSColorPickerViewDelegate: AnyObject {
    func didSelect(color: UIColor, pickerView: DSColorPickerViewType)
}
