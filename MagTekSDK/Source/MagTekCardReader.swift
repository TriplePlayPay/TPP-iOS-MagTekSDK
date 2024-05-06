import Foundation

public class MagTekCardReader {
    
    private class func camelCaseToCaps(_ string: String) -> String {
        return string.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
    
    public class func getEventMessage(_ event: MagTekTransactionEvent) -> String {
        return camelCaseToCaps(String(describing: event))
    }
    
    public class func getStatusMessage(_ status: MagTekTransactionStatus) -> String {
        return camelCaseToCaps(String(describing: status))
    }
    
    private let bleController: MagTekBLEController
    
    public init(_ apiKey: String, debug: Bool, debugUrl: String) {
        bleController = MagTekBLEController(MAGTEKTDYNAMO, apiKey: apiKey, apiUrl: debugUrl)
        bleController.setDebug(debug)
    }
    
    public convenience init(_ apiKey: String, debug: Bool) {
        self.init(apiKey, debug: debug, debugUrl: "https://www.tripleplaypay.com")
    }
    
    public convenience init(_ apiKey: String) { // I hate the keyword "convenience" but... API consistency :)
        self.init(apiKey, debug: true, debugUrl: "https://www.tripleplaypay.com")
    }
    
    public func startDeviceDiscovery(_ deviceDiscoveredCallback: @escaping (String, Int32) -> ()) {
        bleController.deviceDiscoveredCallback = deviceDiscoveredCallback
        bleController.startDeviceDiscovery()
    }
    
    public func cancelDeviceDiscovery() {
        bleController.cancelDeviceDiscovery()
        bleController.deviceDiscoveredCallback = nil
    }
    
    public func connect(_ deviceName: String, _ timeoutSeconds: UInt32, _ deviceConnectionCallback: @escaping (Bool) -> ()) {
        bleController.deviceConnectionCallback = deviceConnectionCallback
        bleController.connect(deviceName, DispatchTime.now() + Double(timeoutSeconds))
    }
    
    public func connect(_ deviceName: String, _ deviceConnectionCallback: @escaping (Bool) -> ()) {
        bleController.deviceConnectionCallback = deviceConnectionCallback
        bleController.connect(deviceName, DispatchTime.now() + 10.0) // allow 10 seconds to connect by default
    }
    
    public func disconnect() {
        bleController.deviceConnectionCallback = nil
        bleController.disconnect()
    }
    
    public func getSerialNumber() -> String {
        return bleController.getSerialNumber()
    }
    
    public func startTransaction(_ amount: String, _ deviceTransactionCallback: @escaping ((String, MagTekTransactionEvent, MagTekTransactionStatus) -> ())) {
        bleController.deviceTransactionCallback = deviceTransactionCallback
        bleController.startTransaction(amount)
    }
    
    public func cancelTransaction() {
        bleController.cancelTransaction()
        bleController.deviceTransactionCallback = nil
    }
}
