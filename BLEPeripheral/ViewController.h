//
//  ViewController.h
//  BLEPeripheral
//
//  Created by ShaoLing on 5/2/14.
//  Copyright (c) 2014 dastone.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define TRANSFER_SERVICE_UUID           @"D63D44E5-E798-4EA5-A1C0-3F9EEEC2CDEB"
#define TRANSFER_CHARACTERISTIC_UUID    @"1652CAD2-6B0D-4D34-96A0-75058E606A98"
#define NOTIFY_MTU  20

@interface ViewController : UIViewController <CBPeripheralManagerDelegate>

@end
