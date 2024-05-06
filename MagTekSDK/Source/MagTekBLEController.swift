import Foundation

struct MagTekBluetoothInfo {
    let name: String
    let rssi: Int32
    let address: String
}

class MagTekBLEController: NSObject, MTSCRAEventDelegate {
    
    private let publicMethodTag = String(describing: MagTekBLEController.self)
    private let mtscraMethodTag = "MTSCRA"
    
    private var devices: [String: MagTekBluetoothInfo] = [:]

    private var bluetoothState: MTSCRABLEState?
    private let lib: MTSCRA = MTSCRA()
    
    private var apiUrlEndpoint = "/api/emv"
    private var debug = false

    private var apiUrl: String
    private let apiKey: String
    
    // Triple Play Pay API callbacks
    public var deviceDiscoveredCallback: ((String, Int32) -> ())?
    public var deviceConnectionCallback: ((Bool) -> ())?
    public var deviceTransactionCallback: ((String, MagTekTransactionEvent, MagTekTransactionStatus) -> ())?
    
    // Controller state
    private var lastApprovalState: Bool = false
    private var lastTransactionMessage: String = "NO MESSAGE"
    private var lastTransactionStatus: MagTekTransactionStatus = .noStatus
    private var lastTransactionEvent: MagTekTransactionEvent = .noEvents
    private var deviceSerialNumber: String = "00000000000000000000000000000000"
    private var deviceIsConnecting: Bool = false
    private var deviceIsConnected: Bool = false
    
    /* Initialize:
     * deviceType: Int
     *  needs a device type (for future type-c / lightning cable implementations)
     *  supported device types:
     *   - MAGTEKTDYNAMO
     *   x MAGTEKIDYNAMO (coming soon?)
     * apiKey: String
     *  needs an API key to communicate with Triple Play Pay
     * apiUrl: String
     *  needs to know which Triple Play Pay API to query
     */
    
    public init(_ deviceType: Int, apiKey: String, apiUrl: String) {
        print("version - 0.0.28")

        self.apiKey = apiKey
        self.apiUrl = apiUrl
        
        super.init() // sets up the MTSCRA library
        self.lib.setDeviceType(UInt32(deviceType))
        self.lib.setConnectionType(UInt(BLE_EMV)) // only bluetooth for now
        self.lib.delegate = self // circular ref for mtscra
    }
    
    /* Private functions for simple processes
     * - debugPrint (tag: String, message: String) -> prints a debug message to STDOUT. Takes a tag argument for better organization
     * - emitDeviceIsConnected () -> should get called when the device is determined to be connected; Configures the device
     * - emitDeviceDisconnected () -> should get called when the device has been disconnected
     * - hexStringBytes (string: String): [UInt8] -> needed to parse response from Triple Play Pay API and pass to aquirerResponse. also useful for parsing data from device
     * - dataToHexString (data: Data): String -> inversion of the above method
     * - getDateByteString(): String -> returns a byte string in a format acceptable by the card reader
     */
    
    private func debugPrint(_ tag: String, _ message: String) {
        debug ? print("\(tag): \(message)") : ()
    }
        
    private func emitDeviceIsConnected() {
        lib.clearBuffers()
        deviceSerialNumber = lib.getDeviceSerial()
        lib.sendCommandSync("580101") // set MSR
        lib.sendCommandSync("480101") // set BLE
        deviceConnectionCallback?(true)
        deviceIsConnecting = false
    }
    
    private func emitDeviceDisconnected() {
        deviceConnectionCallback?(false)
        lib.closeDevice() // make sure we aren't connected after the fact
    }
    
    private func hexStringBytes(_ string: String) -> [UInt8] {
        let bytes = Array(string.utf8)
        var data: [UInt8] = []
        for i in stride(from: 1, to: bytes.count, by: 2){
            let ascii = Array<UInt8>(bytes[i - 1...i] + [0])
            let value = UInt8(strtoul(ascii, nil, 16))
            data.append(value)
        }
        return data
    }
    
    private func dataToHexString(_ data: Data) -> String {
        return data.map({ String(format: "%02X", $0) }).joined()
    }
    
    func n12Bytes(_ amount: String) -> [UInt8] {
        let formattedString = String(format: "%12.0f", (Double(amount) ?? 0) * 100)
        return hexStringBytes(formattedString)
    }
    
    private func getDateByteString() -> String {
        let dateComponents: Set<Calendar.Component> = [.month, .day, .hour, .minute, .second, .year]
        let date = Calendar.current.dateComponents(dateComponents, from: Date())
        let year = (date.year ?? 2008) - 2008
        let format = String(repeating: "%02lX", count: 5) + "%04lX"
        return String(format: format, date.month ?? 0, date.day ?? 0, date.hour ?? 0, date.minute ?? 0, date.second ?? 0, year)
    }
    
    private func openHttpConnection(_ url: String) -> URLRequest {
        let url = URL(string: url)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization") // set the API key header
        request.setValue("Content-Type", forHTTPHeaderField: "application/json")
        return request
    }
    
    /* Callback functions for MTSCRA. These are called when an event happens ON THE DEVICE
     *  - bleReaderStateUpdated (state: BLEState) -> `state` contains the phones internal BLE radio status
     *  - onDeviceList (instance: Any, connectionType: Int, deviceList: [Any]) -> 'deviceList' has a list of discovered devices
     *  - onDeviceConnectionDidChange(deviceType: Int, connected: Bool, instance: Any) -> `connected` tells us if the device is connected or not
     *  - onTransactionStatus (data: Data) -> `data` is a byte buffer containing the current transaction status and event
     *  - onDisplayRequestMethod (data: Data) -> `data` is a byte buffer that can be translated to a UTF-8 string. This is a message from the device to the cardholder
     */
    
    func bleReaderStateUpdated(_ state: MTSCRABLEState) {
        debugPrint(mtscraMethodTag, "bleReaderStateUpdated => \(state)")
        self.bluetoothState = state
    }
    
    func onDeviceList(_ instance: Any!, connectionType: UInt, deviceList: [Any]!) {
        debugPrint(mtscraMethodTag, "onDeviceList => size: \(deviceList.count)")
        for device in (deviceList as! [MTDeviceInfo])  {
            if !devices.keys.contains(device.name) {
                devices[device.name] = MagTekBluetoothInfo(
                    name: device.name,
                    rssi: device.rssi,
                    address: device.address
                )
                deviceDiscoveredCallback?(device.name, device.rssi)
            }
        }
    }
    
    func onDeviceConnectionDidChange(_ deviceType: UInt, connected: Bool, instance: Any!) {
        debugPrint(mtscraMethodTag, "onDeviceConnectionDidChange => \(connected)")
        if deviceIsConnecting { // only return the callback during the alloted "connecting" time window
            deviceIsConnected = connected
            if deviceIsConnected {
                emitDeviceIsConnected()
            }
        }
    }
    
    func onTransactionStatus(_ data: Data!) {
        lastTransactionEvent = MagTekTransactionEvent(rawValue: data[0]) ?? .noEvents // fail quietly
        lastTransactionStatus = MagTekTransactionStatus(rawValue: data[2]) ?? .noStatus
        debugPrint(mtscraMethodTag, "onTransactionStatus => Event: \(lastTransactionEvent), Status: \(lastTransactionStatus)")
        DispatchQueue.main.async {
            self.deviceTransactionCallback?( // we need self inside of an async context
                self.lastTransactionMessage,
                self.lastTransactionEvent,
                self.lastTransactionStatus)
        }
    }
    
    func onDisplayMessageRequest(_ data: Data!) {
        lastTransactionMessage = String(data: data, encoding: .utf8) ?? "COULD NOT PARSE DISPLAY MESSAGE"
        if lastTransactionMessage == "TRANSACTION TERMINATED" {
            if lastApprovalState {
                lastApprovalState = false
                lastTransactionMessage = "APPROVED"
            } else {
                lastTransactionMessage = "DECLINED"
            }
        }
        debugPrint(mtscraMethodTag, "onDisplayMessageRequest => \(lastTransactionMessage)")
        DispatchQueue.main.async {
            self.deviceTransactionCallback?( // we need self inside of an async context
                self.lastTransactionMessage,
                self.lastTransactionEvent,
                self.lastTransactionStatus)
        }
    }
    
    func onARQCReceived(_ data: Data!) {
        debugPrint(mtscraMethodTag, "onARQCReceived")
        
        let arqcHexString = dataToHexString(data)
        var request = openHttpConnection(apiUrl + apiUrlEndpoint)
        
        // data includes non-printable characters because it's in TLV format, so we'll pass it as b64
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["payload": arqcHexString])
        
        // make an HTTP request to TPP for processing the EMV data
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                    if json["status"] as! Bool {
                        let message = json["message"] as! [String: Any]
                        let arpc = message["arpc"] as! String
                        self.lastApprovalState = message["approved"] as! Bool
                        
                        var bytes = self.hexStringBytes(arpc)
                        
                        DispatchQueue.main.async {
                            self.lib.setAcquirerResponse(&bytes, length: Int32(bytes.count))
                        }
                    } else {
                        self.lib.cancelTransaction()
                        let errorMessage = json["error"] as! String
                        print("Error from API: \(errorMessage)")
                    }
                } catch let error as NSError {
                    self.lib.cancelTransaction()
                    print("Error in parsing JSON from response")
                    print(error)
                }
            } else if let error = error {
                self.lib.cancelTransaction()
                print("Error in HTTP request / response")
                print(error)
            }
        }.resume()
    }
    
    /* Public functions for MagTekCardReader
     * General:
     *  - isConnected (): Bool -> gives the current connection state
     *  - getSerialNumber (): String -> gets the serial number of the device
     *  - setDebug (debug: Bool) -> sets the MTSCRA and TPP debug print statements to go to stdout
     * Discovery:
     *  - startDeviceDiscovery () -> tells the phone to begin a bluetooth LE device scan
     *  - cancelDeviceDiscovery () -> tells the phone to stop scanning for LE devices
     * Connection:
     *  - connect (name: String, timeout: TimeInterval) -> tells the phone to connect to the device with `name` and
                                                            cancel itself after `timeout` seconds have passed
     *  - disconnect () -> tells the phone to stop attempting to connect
     * Transactions:
     *  - startTransaction (amount: String) -> begins a transaction process on the device with `amount` being charged to the card
     *  - cancelTransaction () -> cancels a running transaction
     */
    
    public func isConnected() -> Bool {
        let connected = lib.isDeviceOpened() && lib.isDeviceConnected()
        debug ? print("isConnected: \(connected)") : ()
        return connected
    }
    
    public func getSerialNumber() -> String {
        let serialNumber = isConnected() ? lib.getDeviceSerial() : "disconnected"
        debug ? print("getSerialNumber: called") : ()
        return serialNumber ?? "Error getting serial number"
    }
    
    public func setDebug(_ debug: Bool) {
        print("debug \(debug ? "enabled" : "disabled")")
        MTSCRA.enableDebugPrint(debug)
        self.debug = debug
    }
    
    public func startDeviceDiscovery() {
        debugPrint(publicMethodTag, "startDeviceDiscovery called")
        // TODO: idea => if we try connecting to a previously discovered device and it is not successful we will exclude that entry from the list
        // fire the callback for each of the already discovered devices.
        devices.forEach({ deviceName, device in deviceDiscoveredCallback?(deviceName, device.rssi) })
        if let state = bluetoothState { // if the bluetooth state has been captured, and it's okay, we can continue
            if (state == 0 || state == 3) { // 0 = Ok, 3 = Disconnected (which is also Ok...)
                lib.startScanningForPeripherals()
            }
        }
    }
    
    public func cancelDeviceDiscovery() {
        debugPrint(publicMethodTag, "cancelDeviceDiscovery called")
        lib.stopScanningForPeripherals()
    }
    
    public func connect(_ deviceName: String, _ timeout: DispatchTime) {
        debugPrint(publicMethodTag, "connect called")
        if let device = self.devices[deviceName] {
            debugPrint(publicMethodTag, "connecting to device \(deviceName)")
            deviceIsConnecting = true
            lib.setAddress(device.address)
            lib.openDevice()
            DispatchQueue.main.asyncAfter(deadline: timeout, execute: {
                if self.deviceIsConnecting {
                    self.debugPrint("CONNECT TIMEOUT", "called after \(timeout) second(s)")
                    self.deviceIsConnecting = false // set the device to not connecting so we dont report a boolean after the timeout
                    self.deviceIsConnected ? self.emitDeviceIsConnected() : self.emitDeviceDisconnected() // ensure we emit SOMETHING
                }
            })
        } else if self.debug {
            print("connect: could not find a device with name \(deviceName)")
        }
    }
    
    public func disconnect() {
        debugPrint(publicMethodTag, "disconnect called")
        DispatchQueue.main.async {
            self.lib.clearBuffers() // clear buffers before leaving
            self.lib.closeDeviceSync()
        }
    }
    
    public func startTransaction(_ amount: String) {
        debugPrint(publicMethodTag, "startTranas")
        lib.clearBuffers() // clear out buffers before the transaction begins
        
        var amountBytes = n12Bytes(amount)
        var cashbackBytes = n12Bytes("0.00") // not using this for now
        var currencyCode = hexStringBytes("0840")
        
        DispatchQueue.main.async { // starting a transaction is a long-running event
            // we need self inside of an async context for some reason
            self.lib.startTransaction(0x3c, // time limit
                cardType: 7, // always offer all 3
                option: 0, // we aren't using quick EMV
                amount: &amountBytes,
                transactionType: 0, // sale
                cashBack: &cashbackBytes,
                currencyCode: &currencyCode,
                reportingOption: 2) // verbose reporting
        }
    }
    
    public func cancelTransaction() {
        debugPrint(publicMethodTag, "cancelTransaction: called")
        lib.cancelTransaction()
    }
}
