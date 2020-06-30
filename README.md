# ASReceipt
App Store Receipt Parser

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
