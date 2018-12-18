# ASReceipt
App Store Receipt Parser

## Installation

### CocoaPods
```
platform :ios, '10.0'

source 'https://github.com/mrdepth/ASReceipt.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'TestPods' do
	use_frameworks!
	pod 'ASReceipt', :git => 'https://github.com/mrdepth/ASReceipt.git'
end
```

## Usage
```swift
import ASReceipt
do {
  let data = Data(contentsOf: Bundle.main.appStoreReceiptURL!)
  let receipt = try Receipt(data: data)
}
catch {
}
```
