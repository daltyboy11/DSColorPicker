//
//  ViewController.swift
//  SampleApp
//
//  Created by Dalton Sweeney on 2018-07-14.
//  Copyright © 2018 Dalton Sweeney. All rights reserved.
//

import UIKit
import DSColorPicker
import TouchVisualizer

class ViewController: UIViewController {
    
    private var gridColorPickerView: DSGridColorPickerView?
    private var circleColorPickerView: DSCircleColorPickerView?
    
    private let colorPickerSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Circle", "Grid"])
        return control
    }()
    
    private let numberOfColorsPickerView: UIPickerView = UIPickerView(frame: .zero)
    
    private var colors: [CGColor] {
        var colors = [CGColor]()
        for i in 0..<self.numberOfColors {
            let color = UIColor(hue: CGFloat(i) / CGFloat(self.numberOfColors), saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor
            colors.append(color)
        }
        return colors
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Visualizer.start()
        
        numberOfColorsPickerView.dataSource = self
        numberOfColorsPickerView.delegate = self
        numberOfColorsPickerView.selectRow(15, inComponent: 0, animated: false)
        
        colorPickerSegmentedControl.selectedSegmentIndex = 0
        colorPickerSegmentedControl.addTarget(self, action: #selector(didPickColorPicker(_:)), for: .valueChanged)
        
        view.addSubview(colorPickerSegmentedControl)
        view.addSubview(numberOfColorsPickerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        gridColorPickerView = DSGridColorPickerView(frame: .zero, delegate: self, dataSource: self)
        circleColorPickerView = DSCircleColorPickerView(frame: .zero, delegate: self, dataSource: self)
        gridColorPickerView?.backgroundColor = UIColor.white
        circleColorPickerView?.backgroundColor = UIColor.white
        view.addSubview(circleColorPickerView!)
        circleColorPickerView?.show()
    }
    
    override func viewWillLayoutSubviews() {
        let isPortrait = view.bounds.width < view.bounds.height ? true : false
        let pickerViewFrame = CGRect(x: 0,
                                     y: view.bounds.height / 3,
                                     width: view.bounds.width,
                                     height: view.bounds.height * 2 / 3)
        circleColorPickerView?.frame = pickerViewFrame
        gridColorPickerView?.frame = pickerViewFrame
        
        if isPortrait {
            colorPickerSegmentedControl.frame = CGRect(x: view.bounds.width / 2 - 75, y: 50, width: 150, height: 35)
            numberOfColorsPickerView.frame = CGRect(x: view.bounds.width / 2 - 50, y: 100, width: 100, height: 150)
        } else {
            colorPickerSegmentedControl.frame = CGRect(x: 50, y: 50, width: 150, height: 35)
            numberOfColorsPickerView.frame = CGRect(x: 250, y: 25, width: 100, height: 100)
        }
    }
    
    @objc private func didPickColorPicker(_ sender: UISegmentedControl?) {
        if sender?.selectedSegmentIndex == 0 {
            gridColorPickerView?.removeFromSuperview()
            view.addSubview(circleColorPickerView!)
            circleColorPickerView?.show()
        }
        
        if sender?.selectedSegmentIndex == 1 {
            circleColorPickerView?.removeFromSuperview()
            view.addSubview(gridColorPickerView!)
            gridColorPickerView?.show()
        }
    }

}

extension ViewController: DSColorPickerViewDelegate {
    func didSelect(color: UIColor, pickerView: DSColorPickerViewType) {
        view.backgroundColor = color
    }
}

extension ViewController: DSColorPickerViewDataSource {
    var numberOfColors: Int {
        return numberOfColorsPickerView.selectedRow(inComponent: 0)
    }
    
    func color(at index: Int) -> CGColor {
        guard index < colors.count else {
            return UIColor.black.cgColor
        }
        return colors[index]
    }
}

extension ViewController: DSGridColorPickerViewDataSource {
    var maxColumns: Int {
        return 4
    }
}

// MARK: - UIPickerViewDelegate
extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        circleColorPickerView?.reloadPicker()
        gridColorPickerView?.reloadPicker()
    }
}

// MARK: - UIPickerViewDataSource
extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 24
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row)
    }
}

