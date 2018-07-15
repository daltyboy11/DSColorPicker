//
//  GridColorPickerViewDataSource.swift
//  ColorPicker
//
//  Created by Dalton Sweeney on 2018-07-08.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import Foundation

/// Adopt this protocol to be a data source object for a GridColorPickerView
///
public protocol DSGridColorPickerViewDataSource: DSColorPickerViewDataSource {
    /// The maximum number of colors per column in the grid.
    ///
    var maxColumns: Int { get }
}
