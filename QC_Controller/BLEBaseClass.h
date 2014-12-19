//
//  BLEBaseClass.h
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class BLEDeviceClass;

@protocol BLEDeviceClassDelegate
- (void)didUpdateValueForCharacteristic:(BLEDeviceClass*)device Characteristic:(CBCharacteristic *)characteristic;
@end

//BLEDeviceClass
@interface BLEDeviceClass : NSObject
@property (strong)		id<BLEDeviceClassDelegate>	delegate;
- (CBCharacteristic*)getCharacteristic:(NSString*)service_uuid characteristic:(NSString*)characteristic_uuid;
- (BOOL)writeWithResponse:(CBCharacteristic*)characteristic value:(NSData*)data;
- (BOOL)writeWithoutResponse:(CBCharacteristic*)characteristic value:(NSData*)data;
- (BOOL)readRequest:(CBCharacteristic*)characteristic;
- (BOOL)notifyRequest:(CBCharacteristic*)characteristic;
@end

//BLEBaseClass
@interface BLEBaseClass : NSObject
- (id)init;
- (BOOL)scanDevices:(NSString*)uuid;
- (void)scanStop;
- (BLEDeviceClass*)connectService:(NSString*)uuid;
- (BOOL)disconnectService:(NSString*)uuid;
- (void)printDevices;
@end
