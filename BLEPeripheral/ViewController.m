//
//  ViewController.m
//  BLEPeripheral
//
//  Created by ShaoLing on 5/2/14.
//  Copyright (c) 2014 dastone.cn. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristics;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic) NSInteger                         sendDataIndex;
@property (weak, nonatomic) IBOutlet UITextView         *textView;

@property (weak, nonatomic) IBOutlet UISwitch       *advertisingSwitch;

@end

@implementation ViewController

- (IBAction)valueChanged:(UISwitch *)sender {

    NSLog(@"switch on");
    
    self.advertisingSwitch = sender;
    
    if (self.advertisingSwitch.on) {
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]}];
    }else {
        [self.peripheralManager stopAdvertising];
    }

}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    
    NSLog(@"charactristics subscribed");
    
}

- (IBAction)textSend:(UIButton *)sender {
    
    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    self.sendDataIndex = 0;
    
    [self sendData];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    
    NSLog(@"unscbscriber");
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    
    [self sendData];
}

- (void)sendData{
    
    static BOOL sendingEOM = NO;
    
    NSLog(@"sending data");
    
    if (sendingEOM) {
        
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding]
                                         forCharacteristic:self.transferCharacteristics
                                      onSubscribedCentrals:nil];
        if (didSend){
            sendingEOM = NO;
            NSLog(@"Sent: EOM");
        }
    }
    
    if (self.sendDataIndex >= self.dataToSend.length)
        return;
    
    //start to send data
    BOOL didSend = YES;
    
    while (didSend) {
        
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes + self.sendDataIndex
                                       length:amountToSend];
        
        didSend = [self.peripheralManager updateValue:chunk
                                    forCharacteristic:self.transferCharacteristics
                                 onSubscribedCentrals:nil];
        
        if (!didSend){
            return;
        }
        
        NSString *stringFromData = [[NSString alloc]initWithData:chunk encoding:NSUTF8StringEncoding];
        
        NSLog(@"Sent: %@", stringFromData);
        
        self.sendDataIndex += amountToSend;
        
        if (self.sendDataIndex >= self.dataToSend.length) {
            sendingEOM = YES;
            
            BOOL emoSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding]
                                              forCharacteristic:self.transferCharacteristics
                                          onSubscribedCentrals:nil];
            if (emoSent){
                sendingEOM = NO;
                NSLog(@"Sent: EOM");
            }
            return;
        }
            
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    if (!_peripheralManager) {
        _peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
    }
    
    self.advertisingSwitch.on = NO;
    
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    NSLog(@"peripheryal state = %d state poweron = %d", peripheral.state, CBPeripheralManagerStatePoweredOn);
    
    if(peripheral.state != CBPeripheralManagerStatePoweredOn){
        return;
    }
    
    NSLog(@"BLE open");
    
    self.transferCharacteristics = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    CBMutableService *transferService = [[CBMutableService alloc]initWithType: [CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary: YES];
    
    transferService.characteristics = @[self.transferCharacteristics];
    
    [self.peripheralManager addService:transferService];
    
    
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    NSLog(@"add service");
    
    if (error) {
        NSLog(@"add service error %@", [error localizedDescription]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"did start advertising");
    
    if (error) {
        NSLog(@"start advertising error %@", [error localizedDescription]);
    }
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
