import Foundation

struct MagTekBluetoothInfo {
    let name: String
    let rssi: Int32
    let address: String
}

public enum MagTekTransactionEvent: UInt8 { // range from 0x00 -> 0x0a
    case noEvents = 0x00, cardInserted, paymentMethodError, progressChange, waiting, timeout,
         complete, canceled, cardRemoved, contactless, cardSwipe
}

public enum MagTekTransactionStatus: UInt8 { // range all over the place, we have to be explicit
    case noStatus = 0x00, waiting, reading, selectingApplication, selectingCardholderLanguage, selectingCardholderApplication,
         initiatingApplication, readingApplicationData, offlineAuthentication, processingRestrictions, cardholderVerification,
         terminalRiskManagement, terminalActionAnalysis, generatingCryptogram, cardActionAnalysis, onlineProcessing,
         waitingForProcessing, complete, error, approved, declined, canceledByMSR, emvConditionsNotSatisfied,
         emvCardBlocked, contactSelectionFailed, emvCardNotAccepted, emptyCandidateList, applicationBlocked
    case hostCanceled = 0x91
    case applicationSelectionFailed = 0x28, removedCard, collisionDetected, referToHandheldDevice, contactlessComplete,
         requestSwitchToMSR, wrongCardType, noInterchangeProfile
}

class MagTekBLEController: NSObject, MTSCRAEventDelegate {
    private enum MagTekCommand: String {
        case setMSR = "580101"
        case setBLE = "480101"
        case setDateTimePrefix = "030C001800"
    }
    
    private var devices: [String: MagTekBluetoothInfo] = [:]
    private var deviceSerial: String = "00000000000000000000000000000000"
    
    private var bluetoothState: MTSCRABLEState?
    private var scanning: Bool = false
    
    // internal state
    private var displayMessage: String = ""
    private var transactionEvent: MagTekTransactionEvent = .noEvents
    private var transactionStatus: MagTekTransactionStatus = .noStatus
    
    // callback declarations
    public var onDeviceDiscovered: ((String, Int32) -> ())?
    public var onConnection: ((Bool) -> ())?
    public var onTransaction: ((String, MagTekTransactionEvent, MagTekTransactionStatus) -> ())?
    
    private var debug: Bool = false
    
    private let lib: MTSCRA = MTSCRA()
    private let apiKey: String
    private let apiUrl: String
    public init(_ deviceType: Int, apiKey: String, apiUrl: String) {
        print("version - 0.0.23")

        self.apiKey = apiKey
        self.apiUrl = apiUrl

        super.init()
        self.lib.setDeviceType(UInt32(deviceType))
        self.lib.setConnectionType(UInt(BLE_EMV))
        self.lib.delegate = self
    }
    
    // -- MT CALLBACKS --
    func bleReaderStateUpdated(_ state: MTSCRABLEState) { self.bluetoothState = state }
    
    func onDeviceList(_ instance: Any!, connectionType: UInt, deviceList: [Any]!) {
        for device in (deviceList as! [MTDeviceInfo])  {
            if !devices.keys.contains(device.name) {
                self.devices[device.name] = MagTekBluetoothInfo(
                    name: device.name,
                    rssi: device.rssi,
                    address: device.address
                )
                self.onDeviceDiscovered?(device.name, device.rssi)
            }
        }
    }
    
    func onTransactionStatus(_ data: Data!) {
        DispatchQueue.main.async {
            self.transactionEvent = MagTekTransactionEvent(rawValue: data[0])!
            self.transactionStatus = MagTekTransactionStatus(rawValue: data[2])!
            self.onTransaction?(self.displayMessage, self.transactionEvent, self.transactionStatus)
        }
    }
    
    func onDisplayMessageRequest(_ data: Data!) {
        DispatchQueue.main.async {
            self.displayMessage = String(data: data, encoding: .utf8) ?? "COULD NOT PARSE DISPLAY MESSAGE"
            self.onTransaction?(self.displayMessage, self.transactionEvent, self.transactionStatus)
        }
    }
    
    func onARQCReceived(_ data: Data!) {
        var arqc: String = "" // format the same way magtek would
        for byte in data {
            arqc += String(format: "%02X", byte)
        }
        
        let a: String = data.map({ byte in String(format: "%02X", byte) }).joined()
        print("ARQC: \(a)")
        
        print("sending payload to \(self.apiUrl)")
        
        let url = URL(string: "\(self.apiUrl)/api/emv")
        var request = URLRequest(url: url!)
        
        request.httpMethod = "POST"
        // data includes non-printable characters because it's in TLV format, so we'll pass it as b64
        request.httpBody = try! JSONSerialization.data(withJSONObject: ["payload": arqc])
        request.setValue(self.apiKey, forHTTPHeaderField: "Authorization") // set the API key header
        
        // make an HTTP request to TPP for processing the EMV data
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                    if json["status"] as! Bool {
                        //let message = json["message"] as! [String: Any]
                        //let data = message["arpc"] as! [UInt8]
                        //var bytes: [UInt8] = data.map { byte in UInt8(byte) }
                        //var bytes = message["arpc"] as! [UInt8]
                        DispatchQueue.main.async {
                            self.onTransaction?("SUCCESS - PAYMENT NOT PROCESSED (online processing will be supported version 0.1.0)", .complete, .complete)
                            //self.lib.setAcquirerResponse(&bytes, length: Int32(bytes.count))
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
    
    func onTransactionResult(_ data: Data!) {
        let s = data.map { String(format: "%02X ", $0) }
        print("Transaction Data: \(s)")
    }
    
    // -- END CALLBACKS --
    
    // public utility functions
    public func startDeviceDiscovery() {
        // self.devices = [:] // clear devices before scanning
        // ^ the above is legay if we need it again
        
        // instead of clearing devices, just return the already discovered devices.
        // in the future, if we try connecting to the device and it is not successful
        // we will exclude that entry from the list
        for device in self.devices.values {
            self.onDeviceDiscovered?(device.name, device.rssi)
        }
        
        if let state = self.bluetoothState {
            if (state == 0 || state == 3) { // 0 = Ok, 3 = Disconnected (which is also Ok...)
                self.lib.startScanningForPeripherals()
            }
        }
    }
    
    public func connect(_ deviceName: String, _ timeout: TimeInterval) {
        if let device = self.devices[deviceName] {
            self.lib.setAddress(device.address)
            self.lib.openDevice()
            
            let interval: TimeInterval = 0.01
            
            DispatchQueue.main.async {
                var elapsed: TimeInterval = timeout
                Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { timer in
                    if elapsed <= 0.0 {
                        timer.invalidate()
                        self.onConnection?(false)
                    } else if self.lib.isDeviceConnected() && self.lib.isDeviceOpened() {
                        timer.invalidate()
                        self.lib.clearBuffers() // clear the message buffers after connecting
                        self.deviceSerial = self.lib.getDeviceSerial() ?? self.deviceSerial
                        self.lib.sendCommandSync(MagTekCommand.setMSR.rawValue) // put device into MSR mode
                        self.lib.sendCommandSync(MagTekCommand.setBLE.rawValue) // set response mode to BLE, then set date + time
                        self.lib.sendExtendedCommandSync(MagTekCommand.setDateTimePrefix.rawValue + self.deviceSerial + getDateByteString())
                        self.onConnection?(true)
                    }
                    elapsed -= interval
                })
            }
        } else if self.debug {
            print("ERROR in connect:")
            print("- could not find a device with name \(deviceName)")
        }
    }
    
    public func isConnected() -> Bool { return self.lib.isDeviceOpened() && self.lib.isDeviceConnected() }
    public func cancelDeviceDiscovery() { self.lib.stopScanningForPeripherals() }
    public func cancelTransaction() { self.lib.cancelTransaction() }
    
    public func disconnect() -> Bool {
        self.lib.clearBuffers()
        self.lib.closeDeviceSync()
        return self.isConnected()
    }
    
    public func getSerialNumber() -> String {
        if self.lib.isDeviceConnected() {
            return self.lib.getDeviceSerial()
        } else {
            return "disconnected"
        }
    }
    
    public func startTransaction(_ amount: String) {
        self.lib.clearBuffers()
        
        var amountBytes = n12Bytes(amount)
        var cashbackBytes = n12Bytes("0.00") // not using this for now
        var currencyCode = hexStringBytes("0840")
        
        // starting a transaction is quite a long-running event
        DispatchQueue.main.async {
            self.lib.startTransaction(60,
                cardType: 7, // always offer all 3
                option: 0, // we aren't using quick EMV
                amount: &amountBytes,
                transactionType: 0, // sale
                cashBack: &cashbackBytes,
                currencyCode: &currencyCode,
                reportingOption: 2) // verbose reporting
        }
    }
        
    // public setters
    public func setDebug(_ debug: Bool) {
        MTSCRA.enableDebugPrint(debug)
        self.debug = debug
    }
}
