# DSColorPicker
Lightweight views for your color picking needs.

## CocoaPods Install

Add `pod 'DSColorPicker'` to your Podfile and then run `$ pod install`

## Usage

To use the provided classes, `import DSColorPicker`

### Presenting the color picker
After creating either a Grid or Circle ColorPickerView, invoke `show(animated:completion:)`. By default, the presentation is animated and the completion handler does nothing.

Example:

In a view controller

```swift
let gridColorPickerView = GridColorPickerView(frame: self.view.bounds, delegate: self, dataSource: self)
view.addSubview(gridColorPickerView)
gridColorPickerView.show()
```

![Presenting](https://github.com/daltyboy11/DSColorPicker/blob/master/Demo%20Videos/show_picker.gif)

### Reloading a color picker
After updating a color picker's `dataSource` in some manner, invoke `reload(animated:completion:)` to communicate the changes to the color picker.

Example - Reloading the picker after changing the number of colors from 10 to 15:

![Circle](https://github.com/daltyboy11/DSColorPicker/blob/master/Demo%20Videos/reload_circle.gif)
![Grid](https://github.com/daltyboy11/DSColorPicker/blob/master/Demo%20Videos/reload_grid.gif)

### Providing data to the picker

Adopt the `ColorPickerViewDataSource` to provide the number of colors and color values to the picker.

Example of a conforming view controller that provides various RGB formatted colors to the picker:

```swift
extension ViewController: ColorPickerViewDataSource {
    var numberOfColors: Int {
        return 16
    }
    
    func color(at index: Int) -> CGColor {
        let color = UIColor(hue: CGFloat(index) / CGFloat(self.numberOfColors), saturation: 1.0, brightness: 1.0, alpha: 1.0).cgColor
        return color
    }
}
```

### Providing data to a `GridColorPickerView`

To provide data to a GridColorPickerView, adopt the `GridColorPickerViewDataSource` protocol. This data source has the same requirements as the `ColorPickerViewDataSource`, with the addition of `maxColumns`, which specifies the maximum allowable number of columns in the grid.

Example - Adding colors one by one to the picker with `maxColumns` set to `4`:

### Handling events

Receive a notification when the user selects a color in the picker by adopting the `ColorPickerViewDelegateProtocol`

Example:

```swift
extension ViewController: ColorPickerViewDelegate {
    // A UIViewController subclass is the delegate for a picker view, and changes its view's background color when a color is selected by the user in a picker view.
    func didSelect(color: UIColor, pickerView: ColorPickerViewType) {
        view.backgroundColor = color
    }
    
}
```

![User interaction](https://github.com/daltyboy11/DSColorPicker/blob/master/Demo%20Videos/user_interaction.gif)
