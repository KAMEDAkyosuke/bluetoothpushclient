//
//  main.m
//  bluetoothpushclient
//
//  Created by KAMEDAkyosuke on 2013/01/24.
//

#import <Foundation/Foundation.h>

#import <IOBluetooth/IOBluetooth.h>

static NSString* TARGET_NAME = @"INSERT_YOURE_TARGET_DEVICE_NAME";
static BluetoothRFCOMMChannelID channelId;

@interface MyRegisterForConnectNotification : NSObject<IOBluetoothRFCOMMChannelDelegate>
+(void)newConnection:(IOBluetoothUserNotification*)notification fromDevice:(IOBluetoothDevice*)device;
@end

@implementation MyRegisterForConnectNotification

+(void)newConnection:(IOBluetoothUserNotification*)notification fromDevice:(IOBluetoothDevice*)device
{
    NSLog(@"%s", __func__);
    NSLog(@"[device isConnected] = %@", [device isConnected] ? @"YES" : @"NO");
    
    IOReturn r;
    MyRegisterForConnectNotification* delegate = [[MyRegisterForConnectNotification alloc] init];
    r = [device performSDPQuery:delegate];
    if(r != kIOReturnSuccess){
        NSLog(@"performSDPQuery ON ERROR : 0x%x", r);
    }
}

// performSDPQuery result
- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status {
    NSLog(@"%s", __func__);

    IOReturn r;
    if (status != kIOReturnSuccess) {
        NSLog(@"SDP query got status %d", status);
        return;
    }
    
    for(IOBluetoothSDPServiceRecord *service in device.services){
        NSLog(@"%@", [service getServiceName]);
        IOReturn r = [service getRFCOMMChannelID:&channelId];
        if(r == kIOReturnSuccess){
            NSLog(@"ChannelID FOUND %d", channelId);
            break;
        }
    }
    
    IOBluetoothRFCOMMChannel *channel;
    r = [device openRFCOMMChannelAsync:&channel
                         withChannelID:channelId
                              delegate:self];
    
    if(r != kIOReturnSuccess){
        NSLog(@"openRFCOMMChannelSync ON ERROR : 0x%x", r);
        NSLog(@"kIOReturnNotOpen %@", r == kIOReturnNotOpen ? @"YES" : @"NO");
    }
}

// IOBluetoothRFCOMMChannelDelegate
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    NSLog(@"%s", __func__);
}
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel status:(IOReturn)error
{
    NSLog(@"%s", __func__);

    IOReturn r;

    if(error != kIOReturnSuccess){
        NSLog(@"%s, error = 0x%x", __func__, error);
        r = [rfcommChannel closeChannel];
        if( r != kIOReturnSuccess){
            NSLog(@"closeChannel ON ERROR, 0x%x", r);
        }
    }
    
    short l = htons(strlen("HELLO WORLD"));
    r = [rfcommChannel writeSync:&l length:sizeof(short)];
    if( r != kIOReturnSuccess){
        NSLog(@"writeSync ON ERROR");
    }
    r = [rfcommChannel writeSync:"HELLO WORLD" length:strlen("HELLO WORLD")];
    if( r != kIOReturnSuccess){
        NSLog(@"writeSync ON ERROR");
    }
    r = [rfcommChannel closeChannel];
    if( r != kIOReturnSuccess){
        NSLog(@"closeChannel ON ERROR, 0x%x", r);
    }
}
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __func__);

    IOReturn r;
    if([rfcommChannel isOpen]){
        r = [rfcommChannel closeChannel];
        if(r != kIOReturnSuccess){
            NSLog(@"closeChannel ON ERROR, 0x%x", r);
        }
    }
    
    IOBluetoothDevice *device = [rfcommChannel getDevice];
    if([device isConnected]){
        r = [device closeConnection];
        if(r != kIOReturnSuccess){
            NSLog(@"closeConnection ON ERROR, 0x%x", r);
        }
    }
}
- (void)rfcommChannelControlSignalsChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __func__);
}
- (void)rfcommChannelFlowControlChanged:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __func__);
}
- (void)rfcommChannelWriteComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel refcon:(void*)refcon status:(IOReturn)error
{
    NSLog(@"%s", __func__);
}
- (void)rfcommChannelQueueSpaceAvailable:(IOBluetoothRFCOMMChannel*)rfcommChannel
{
    NSLog(@"%s", __func__);
}

@end

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        IOBluetoothUserNotification *notification;
        notification = [IOBluetoothDevice registerForConnectNotifications:[MyRegisterForConnectNotification class]
                                                                 selector:@selector(newConnection:fromDevice:)];
        
        IOReturn r;
        IOBluetoothDevice *target = nil;
        
        NSArray *devices = [IOBluetoothDevice pairedDevices];
        int i=0;
        for(IOBluetoothDevice *device in devices){
            NSLog(@"%d : %@", i++, device.name);
            
            if([TARGET_NAME isEqualToString:device.name]){
                target = device;
                break;
            }
        }

        r = [target openConnection];
        if(r != kIOReturnSuccess){
            NSLog(@"openConnection ON ERROR : 0x%x", r);
        }
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
