//
//  MTSCRA.h
//  MTSCRA
//
//  Created by Imran Jahanzeb on 1/31/12.
//  Copyright (c) 2012 MagTek. All rights reserved.


#import <AudioUnit/AudioUnit.h>
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreBluetooth/CoreBluetooth.h>
//#if TARGET_OS_IPHONE

#import <ExternalAccessory/ExternalAccessory.h>

//#import "MTCardData.h"
#import <AVFoundation/AVFoundation.h>
//#endif


#ifdef DEBUG
#define _DBGPRNT
#endif

/*
 Error code
 */

#define ERROR_SUCCESS 0
#define ERROR_TIMEOUT 1
#define ERROR_DEVICE_NOT_OPEN 5
#define ERROR_INVALID_PARAMETER 6
#define ERROR_DEVICE_COMMUNICATION_ERROR 7
#define ERROR_OTHER_ERROR 9
#define ERROR_BUSY 15
#define ERROR_DATA_IS_NOT_EXIST 16
#define ERROR_UNKNOWN 255

@class IMTSCRAData;
@class MTSCRADevice;

enum
{
    TLV_OPSTS,
    TLV_CARDSTS,
    TLV_TRACKSTS,
    
    TLV_CARDNAME,
    TLV_CARDIIN,
    TLV_CARDLAST4,
    TLV_CARDEXPDATE,
    TLV_CARDSVCCODE,
    TLV_CARDPANLEN,
    
    TLV_ENCTK1,
    TLV_ENCTK2,
    TLV_ENCTK3,
    
    TLV_DEVSN,
    TLV_DEVSNMAGTEK,
    TLV_DEVFW,
    TLV_DEVNAME,
    TLV_DEVCAPS,
    TLV_DEVSTATUS,
    TLV_TLVVERSION,
    TLV_DEVPARTNUMBER,
    TLV_CAPMSR,
    TLV_CAPTRACKS,
    TLV_CAPMAGSTRIPEENCRYPTION,
    TLV_KSN,
    TLV_CMAC,
    TLV_SWPCOUNT,
    TLV_BATTLEVEL,
    TLV_CFGTLVVERSION,
    TLV_CFGDISCOVERY,
    TLV_CFGCARDNAME,
    TLV_CFGCARDIIN,
    TLV_CFGCARDLAST4,
    TLV_CFGCARDEXPDATE,
    TLV_CFGCARDSVCCODE,
    TLV_CFGCARDPANLEN,
    TLV_MSKTK1,
    TLV_MSKTK2,
    TLV_MSKTK3,
    TLV_HASHCODE,
    TLV_SESSIONID,
    TLV_MAGNEPRINT,
    TLV_MAGNEPRINT_STS
    
};
typedef NSUInteger MTSCRATransactionData;

typedef NS_ENUM(NSUInteger, MTSCRATransactionStatus)
{
    TRANS_STATUS_OK,
    TRANS_STATUS_START,
    TRANS_STATUS_ERROR
};


enum
{
    TRANS_EVENT_OK = 1,
    TRANS_EVENT_ERROR=2,
    TRANS_EVENT_START = 4,
    
};
typedef NSUInteger MTSCRATransactionEvent;

enum
{
    CAP_MASKING = 1,
    CAP_ENCRYPTION=2,
    CAP_CARD_AUTH = 4,
    CAP_DEVICE_AUTH = 8,
    CAP_SESSION_ID = 16,
    CAP_DISCOVERY= 32,
};
typedef NSUInteger MTSCRACapabilities;

enum
{
    MAGTEKAUDIOREADER, //iOS Only
    MAGTEKIDYNAMO,
    MAGTEKDYNAMAX,
    MAGTEKEDYNAMO,
    MAGTEKUSBMSR, //OSX Only
    MAGTEKKDYNAMO,
    MAGTEKTDYNAMO,
    MAGTEKDYNAWAVE,
    MAGTEKMDYNAMO,
    MAGTEKNONE
    
};
typedef NSUInteger MTSCRADeviceType;


enum
{
    BLE,
    BLE_EMV,
    USB,
    Lightning,
    NONE
};
typedef NSUInteger ConnectionType;
 

enum
{
    Connection,
    CommandMessageData,
    CardMessageData,
    BLERawMessage,
    DeviceInfo,
    RawDataMessage
    
};
typedef int MTSCRADebugDomain;


enum
{
    OK,
    OFF,
    RESETTING,
    DISCONNECTED,
    UNSUPPORTED,
    UNAUTHORIZED,
    UNKNOWN
    
};
typedef int MTSCRABLEState;

@interface MTDeviceInfo : NSObject
@property(nonatomic, strong) NSString *Address;
@property(nonatomic, strong) NSString *Name;
@property(nonatomic, strong) NSString *ProductID;
@property(nonatomic) int RSSI;
@property ConnectionType connectionType;
@end

@interface MTConnectionInfo : NSObject
@property(nonatomic) int disconnectStatus;
@property(nonatomic, strong) NSString *disconnectReason;
@property(nonatomic, strong) CBPeripheral *peripheral;
@end

@interface MTDebugInfo : NSObject
@property(nonatomic, strong) NSString *name;
@property(nonatomic) MTSCRADebugDomain debugDomain;
@property(nonatomic, strong) NSString *value;
@property ConnectionType connectionType;
@property (nonatomic,strong) NSDate* timeStamp;
@end


//#if TARGET_OS_IPHONE

@protocol EADetectorDelegate <NSObject>

@optional
- (void) DeviceConnected;
- (void) DeviceDisconnected;

@end

@interface EADetector : NSObject

@property (nonatomic, weak) id<EADetectorDelegate> delegate;
@property (nonatomic, readonly, getter=getAccessories) NSArray* accesories;

+ (id) sharedDetector;

- (NSArray*) getAccessories;
- (UInt32) getDeviceType : (EAAccessory*) accessory;
- (NSString*) getDeviceTypeString : (EAAccessory*) accessory;

@end

//#endif

@interface MTCardData : NSObject

- (id)initWithCardData:(NSString*)cardData;

@property(nonatomic, strong) NSString *cardIIN;
@property(nonatomic, strong) NSString *cardData;
@property(nonatomic, strong) NSString *cardLast4;
@property(nonatomic, strong) NSString *cardName;

@property (strong, nonatomic) NSString *cardLastName;
@property (strong, nonatomic) NSString *cardMiddleName;
@property (strong, nonatomic) NSString *cardFirstName;


@property(nonatomic, strong) NSString *cardExpDate;
@property(nonatomic, strong) NSString *cardServiceCode;
@property(nonatomic, strong) NSString *cardStatus;
@property(nonatomic, strong) NSString *responseData;
@property(nonatomic, strong) NSString *maskedTracks;
@property(nonatomic, strong) NSString *encryptedTrack1;
@property(nonatomic, strong) NSString *encryptedTrack2;
@property(nonatomic, strong) NSString *encryptedTrack3;
@property(nonatomic, strong) NSString *encryptionStatus;
@property(nonatomic, strong) NSString *maskedTrack1;
@property(nonatomic, strong) NSString *maskedTrack2;
@property(nonatomic, strong) NSString *maskedTrack3;
@property(nonatomic, strong) NSString *trackDecodeStatus;
@property(nonatomic, strong) NSString *encryptedMagneprint;
@property(nonatomic, strong) NSString *magneprintStatus;
@property(nonatomic, strong) NSString *deviceSerialNumber;
@property(nonatomic, strong) NSString *deviceSerialNumberMagTek;
@property(nonatomic, strong) NSString *encrypedSessionID;
@property(nonatomic, strong) NSString *deviceKSN;
@property(nonatomic, strong) NSString *deviceFirmware;
@property(nonatomic, strong) NSString *deviceName;
@property(nonatomic, strong) NSString *deviceCaps;
@property(nonatomic, strong) NSString *deviceStatus;
@property(nonatomic, strong) NSString *tlvVersion;
@property(nonatomic, strong) NSString *devicePartNumber;
@property(nonatomic, strong) NSString *capMSR;
@property(nonatomic, strong) NSString *capTracks;
@property(nonatomic, strong) NSString *capMagStripeEncryption;
@property(nonatomic, strong) NSString *maskedPAN;
@property(nonatomic) long cardPANLength;
@property(nonatomic, strong) NSString *additionalInfoTrack1;
@property(nonatomic, strong) NSString *additionalInfoTrack2;
@property(nonatomic, strong) NSString *responseType;
@property(nonatomic) long batteryLevel;
@property(nonatomic) long swipeCount;
@property(nonatomic, strong) NSString *firmware;
@property(nonatomic, strong) NSString *tagValue;
@property(nonatomic) int magnePrintLength;
@property(nonatomic) int cardType;
@property(nonatomic, strong) NSString *cardExpDateMonth;
@property(nonatomic, strong) NSString *cardExpDateYear;
@property(nonatomic, strong) NSString *cardPAN;
@property(nonatomic, strong) NSString *track1DecodeStatus;
@property(nonatomic, strong) NSString *track2DecodeStatus;
@property(nonatomic, strong) NSString *track3DecodeStatus;
@property(nonatomic, strong) NSDate* timeStamp;
@end

typedef void (^MTSCRADebugCallback)(MTDebugInfo*);
@protocol MTSCRAEventDelegate <NSObject>
@optional
- (void) onDataReceived: (MTCardData*)cardDataObj instance:(id)instance;
- (void) cardSwipeDidStart:(id)instance;
- (void) cardSwipeDidGetTransError;
- (void) onDeviceConnectionDidChange:(MTSCRADeviceType)deviceType connected:(BOOL) connected instance:(id)instance;
- (void) bleReaderConnected:(CBPeripheral*)peripheral;
- (void) bleReaderDidDisconnected:(MTConnectionInfo*)connectionInfo;
- (void) bleReaderDidDiscoverPeripheral;
- (void) bleReaderStateUpdated:(MTSCRABLEState)state;
- (void) onDeviceResponse:(NSData*)data;
- (void) onDeviceError:(NSError*)error;
//EMV delegate
- (void) OnTransactionStatus:(NSData*)data;
- (void) OnDisplayMessageRequest:(NSData*)data;
- (void) OnUserSelectionRequest:(NSData*)data;
- (void) OnARQCReceived:(NSData*)data;
- (void) OnTransactionResult:(NSData*)data;
- (void) OnEMVCommandResult:(NSData*)data;
- (void) onDeviceExtendedResponse:(NSString*)data;
- (void) deviceNotPaired;
- (void) didGetRSSI:(int)RSSI error:(NSError*)error;


- (void) onDeviceList:(id)instance connectionType:(ConnectionType)connectionType deviceList:(NSArray*)deviceList;
@end



@interface MTSCRA : NSObject <NSStreamDelegate>
{
    
 
@private
    
    NSString *cardIIN;
    NSString *cardData;
    NSString *cardLast4;
    NSString *cardName;
    
    NSString *cardLastName;
    NSString *cardMiddleName;
    NSString *cardFirstName;
    
    NSString *cardExpDate;
    NSString *cardServiceCode;
    NSString *cardStatus;
    NSString *responseData;
    NSString *maskedTracks;
    NSString *stdTrack1;
    NSString *stdTrack2;
    NSString *stdTrack3;
    NSString *encryptedTrack1;
    NSString *encryptedTrack2;
    NSString *encryptedTrack3;
    NSString *encryptionStatus;
    NSString *maskedTrack1;
    NSString *maskedTrack2;
    NSString *maskedTrack3;
    NSString *trackDecodeStatus;
    NSString *encryptedMagneprint;
    NSString *magneprintStatus;
    NSString *deviceSerialNumber;
    NSString *deviceSerialNumberMagTek;
    NSString *encrypedSessionID;
    NSString *deviceKSN;
    NSString *deviceFirmware;
    NSString *deviceName;
    NSString *deviceCaps;
    NSString *deviceStatus;
    NSString *tlvVersion;
    NSString *devicePartNumber;
    NSString *capMSR;
    NSString *capTracks;
    NSString *capMagStripeEncryption;
    NSString *maskedPAN;
    NSString *additionalInfoTrack1;
    NSString *additionalInfoTrack2;
    NSString *responseType;
    NSString *batteryLevel;
    NSString *swipeCount;
    
    
    AudioUnit					rioUnit;
    AURenderCallbackStruct		inputProc;
    
    AudioStreamBasicDescription	thruFormat;
    AudioBufferList             bufferlist;
    AudioBuffer                 buf;
    AudioBuffer                 buf1;
    BOOL                        isDeviceConnected;
    long eventMask;
    long devCapabilities;
    
    Byte *commandBits;
    int commandBitsIndex;
#if TARGET_OS_IPHONE
    EAAccessory * _accessory;
    //EASession *   _session;
    EAAccessoryManager *eaAccessory;
    //AVAudioSession *audioSession;
#endif
    NSMutableString *dataFromiDynamo;
    NSMutableString *deviceProtocolString;
    NSMutableString *configParams;
    
    
    
    MTSCRADeviceType devType;
    
}

void audioReaderDelegate(void*self, int status);

//Initialize device
-(BOOL) openDevice;

-(BOOL) openDeviceSync;

//Close device
-(BOOL) closeDevice;

-(BOOL) closeDeviceSync;

//Retrieves if the device is connected
- (BOOL) isDeviceConnected;

//Retrieve Masked Track1 if any
- (NSString *) getTrack1Masked;

//Retrieve Masked Track2 if any
- (NSString *) getTrack2Masked;

//Retrieve Masked Track3 if any
- (NSString *) getTrack3Masked;

//Retrieves existing stored Masked data, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMaskedTracks;

//Retrieve Encrypted Track1 if any
- (NSString *) getTrack1;

//Retrieve Encrypted Track2 if any
- (NSString *) getTrack2;

//Retrieve Encrypted Track3 if any
- (NSString *) getTrack3;

//Retrieve Encrypted MagnePrint, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMagnePrint;

//Retrieve MagnePrint Status, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getMagnePrintStatus;

//Retrieve Device Serial Number
- (NSString *) getDeviceSerial;

//Retrieve Device Serial Number created by MagTek
- (NSString *) getMagTekDeviceSerial;

//Retrieve Firmware Vsersion Number
- (NSString *) getFirmware;

//Retrieve Device Name
- (NSString *) getDeviceName;

//Retrieve Device Capabilities
- (NSString *) getDeviceCaps;

//Retrieve Device Status
- (NSString *) getDeviceStatus;

//Retrieve TLV Version
- (NSString *) getTLVVersion;

//Retrieve Device Part Number
- (NSString *) getDevicePartNumber;

//Retrieve Key Serial Number
- (NSString *) getKSN;

//Retrieve individual tag value, only supported in audio reader
- (NSString *) getTagValue: (UInt32)tag;

//Retrieve MSR Capability
- (NSString *) getCapMSR;

//Retrieve Tracks Capability
- (NSString *) getCapTracks;

//Retrieve MagStripe Encryption Capability
- (NSString *) getCapMagStripeEncryption;

- (int) getMagnePrintLength;

//Send Commands To The Device

- (int) sendCommandToDevice:(NSString *)pData __attribute__((deprecated))  __deprecated_msg("use sendcommandWithLength instead.");

- (int) sendcommandWithLength:(NSString *)command;

- (void) setTimeout : (NSUInteger) timeoutMS;
+ (void) setTimeFrame : (unsigned int) ms;
+ (void) enableDebugPrint : (BOOL) enabled;

- (NSString*)sendCommandSync:(NSString*)command;

//Sets the protocol String for iDynamo
- (void) setDeviceProtocolString:(NSString *)pData;
//Sets the config params for SDK
- (void) setConfigurationParams:(NSString *)pData;

//Setup the events to listen for
- (void) listenForEvents:(UInt32)event;

//Retrieves the Device Type
- (long) getDeviceType;


//Retrieve card PAN
- (NSString*) getCardPAN;

//Retrieves the Length of teh PAN
- (int) getCardPANLength;

//Retrieve Session ID, only supported for iDynamo, it will return a empty string in audio reader
- (NSString *) getSessionID;

//Retrieved the whole Response from the reader
- (NSString *) getResponseData;

//Retrieves the Name in the Card
- (NSString *) getCardName;

//Retrieves the IIN in the Card
- (NSString *) getCardIIN;

//Retrieves the Last 4 of the PAN
- (NSString *) getCardLast4;

//Retrieves the Expiration Date
- (NSString *) getCardExpDate;

- (NSString*) getExpDateMonth;

- (NSString*) getExpDateYear;

//Retrieves the Service Code
- (NSString *) getCardServiceCode;

//Retrieves the Card Status
- (NSString *) getCardStatus;

//Retrieves the Track Decode Status
- (NSString *) getTrackDecodeStatus;

- (NSString*) getTrack1DecodeStatus;
- (NSString*) getTrack2DecodeStatus;
- (NSString*) getTrack3DecodeStatus;

//Retrieve Response Type
- (NSString *) getResponseType;

//Sets the type of device to Open
-(void) setDeviceType: (UInt32)deviceType;





//Retrieves device opened status
- (BOOL) isDeviceOpened;

// Clears all the buffer that is stored during card swipe or command response
- (void) clearBuffers;

//Retrieves the battery Level
- (long) getBatteryLevel;

//Retrieves the swipe count
- (long) getSwipeCount;

//Gets the current version of the SDK.
- (NSString *) getSDKVersion;

//Retrieves the Operation Status
- (NSString *) getOperationStatus;

//Config Functions
- (NSString *) getEncryptionStatus;

// Stops scanning for surrounding Peripherals
- (void)stopScanningForPeripherals;

// Starts scanning for surrounding Peripherals
- (void)startScanningForPeripherals;

// Sets the UUID String
- (void)setUUIDString:(NSString *)uuidString __deprecated_msg("setUUIDString will be deprecated in future, use setAddress instead.");

// Retrieves the currently connected Peripheral
- (CBPeripheral *)getConnectedPeripheral;

// Retrieves the list of Peripherals that are in range and can be connected to
- (NSMutableArray *)getDiscoveredPeripherals;


// Retrieves the BLE device information
- (NSDictionary*)getDeviceInformationDictionary;

// Start EMV Transaction
- (int) startTransaction:(Byte)timeLimit cardType:(Byte)cardType option:(Byte)option amount:(Byte*)amount transactionType:(Byte)transactionType cashBack:(Byte*)cashBack currencyCode:(Byte*)currencyCode reportingOption:(Byte)reportingOption;

//Set User Selection for requests coming from card
- (int) setUserSelectionResult:(Byte)status selection:(Byte)selection;

//Sample to send resopond back to device
- (int) setAcquirerResponse:(Byte*)response length:(int)length;

//Cancel Transaction
- (int) cancelTransaction;

//Check if device support EMV
- (BOOL) isDeviceEMV;

//send extended command to EMV Devices;
- (int) sendExtendedCommand:(NSString*)commandIn;

- (NSString*) sendExtendedCommandSync :(NSString*) commandIn;

- (int) getLastError;

//Return Card Data TLV Pay load
- (NSString*) getTLVPayload;

//Set device address for BLE devices.
- (void)setAddress:(NSString *)address;

//Get bluetooth device signal strength, only apply to Bluetooth LE devices.
- (int)getBluetoothRSSI;

//FOR USB ONLY
- (void) setConnectionType: (ConnectionType)connectionType;
- (ConnectionType)getConnectionType;




//MTSCRA Delegate
@property (nonatomic, weak) id <MTSCRAEventDelegate> delegate;
@property (nonatomic, strong) MTSCRADebugCallback debugInfoCallback;




#pragma mark MAC_OSX_FUNCTIONS

- (void)requestDeviceList:(ConnectionType)type;

// USB Only
- (int)getProductID;

@end
