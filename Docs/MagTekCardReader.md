# MagTekCardReader
This is the main class for the SDK. it provides all of the functionality needed to scan for, connect to, and make transactions with MagTek (tDyanmo/iDynamo) devices.
## Init
In order to initialize the card reader interface, you must pass in your _Triple Play Pay_ API key.
```swift
// note: not an actual API key
let cardReader = MagTekCardReader("b5918e9a-c50f-491a-bcae-d52e0556c498")
```
## Start Device Discovery
Before you can connect to a device, you need to scan for available targets. In order to do this, you can simply call `startDeviceDiscovery` on a `MagTekCardReader` object. The function accepts one argument which is a callback. The callback accepts two arguments: `(String, Int32)`. These two values represent the name of the device and the signal strength
```swift
// this function only accepts a callback with two arguments
cardReader.startDeviceDiscovery({ name, rssi in 
    // add the newly discovered device to some sort of container to display in the UI
    deviceList.append([name, rssi])
})
```
## Cancel Device Discovery
Once you've found the device to pair with, it's a good idea to stop the internal radio from scanning. Use the `cancelDeviceDiscovery` method to cancel the scan.
```swift
cardReader.cancelDeviceDiscovery()
```
## Connect
In order to connect to a device, you need its name from the `startDeviceDiscovery` method. The `connect` method takes in two arguments: the first one is the `String` representing the device's name. the second argument is a callback. This callback accepts one argument which is a boolean that represents if the device has been connected or not. Eventually, after 10 seconds, if the device has not connected, the callback will be returned with `false` as the argument.
```swift
cardReader.connect(deviceName, { connected in
    if connected {
        // update UI to say connected
    } else {
        // update UI to tell user connection failed
    }
})
```
## Disconnect
In order to sever the connection, use the `disconnect` method
```swift
cardReader.disconnect()
```
## Start Transaction
Once the device is connected, you will have the ability to initiate an EMV transaction. The method `startTransaction` takes two arguments. The first argument is a string representing the dollar amount of the transaction. The decimal `.` must be in the string.
```swift
cardReader.startTransaction("1.01", { message, event, status in
    // check to see if the transaction is completed
    if event == .complete {
        // update UI
    }
    
    // set some UI component to the current message
    transactionMessage = message
})
```
## Cancel Transaction
In order to prematurely complete a transaction, you can use the `cancelTransaction` method
```swift
cardReader.cancelTransaction()
```
#### Transaction Events
- noEvents
- cardInserted
- paymentMethodError
- progressChange
- waiting
- timeout
- complete
- canceled
- cardRemoved
- contactless
- cardSwipe
#### Transaction Statuses
- coming soon
