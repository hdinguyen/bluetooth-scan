//
//  ViewController.m
//  BluetoothScan
//
//  Created by Nguyenh on 11/24/14.
//  Copyright (c) 2014 Nguyenh. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <MessageUI/MessageUI.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
{
    CBCentralManager *_centralManager;
    CBPeripheral *_discoveredPeripheral;
    NSMutableArray* _mData;
    NSMutableString* _strData;
    NSArray* _tmpService;
}

@property (weak, nonatomic) IBOutlet UITableView *mTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _strData = [NSMutableString string];
    _mData = [NSMutableArray array];
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        [[[UIAlertView alloc]initWithTitle:@"Error" message:@"Please turn Bluetooth on" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    
    if (central.state == CBCentralManagerStatePoweredOn) {
        // Scan for devices
        
        [_strData appendString:@">>>>>>>>>> START SCAN DEVICE <<<<<<<<<<\n"];
        [_centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        NSLog(@"Scanning started");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    BOOL exist = NO;
    
    for (CBPeripheral* i in _mData)
    {
        if ([i.name isEqualToString:peripheral.name])
        {
            exist = YES;
            return;
        }
    }
    
    [_strData appendFormat:@"FOUND DEVICE: name: [%@]\n",peripheral.name];
    
    if (!exist)
    {
        [_mData addObject:peripheral];
        [_mTableView reloadData];
    }
    
    /*
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    if (_discoveredPeripheral != peripheral) {
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        _discoveredPeripheral = peripheral;
        
        // And connect
        NSLog(@"Connecting to peripheral %@", peripheral);
        [_centralManager connectPeripheral:peripheral options:nil];
    }
     */
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect");
    [self cleanup];
}

- (void)cleanup {
    
    // See if we are subscribed to a characteristic on the peripheral
//    if (_discoveredPeripheral.services != nil) {
//        for (CBService *service in _discoveredPeripheral.services) {
//            if (service.characteristics != nil) {
//                for (CBCharacteristic *characteristic in service.characteristics) {
//                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
//                        if (characteristic.isNotifying) {
//                            [_discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
//                            return;
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    [_centralManager cancelPeripheralConnection:_discoveredPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Connected");
    [_centralManager stopScan];
    NSLog(@"Scanning stopped");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    [_strData appendString:@"===== START DISCOVERY SERVICE =====\n"];
    _tmpService = peripheral.services;
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
    [_strData appendString:@"===== STOP DISCOVERY SERVICE =====\n"];
    DISMISS_LOADING();
    // Discover other characteristics
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        DISMISS_LOADING();
        [self cleanup];
        return;
    }
    [_strData appendFormat:@">>>>> START DISCOVERY SERVICE: <<<<<%@\n", [service.UUID UUIDString]];
    for (CBCharacteristic *characteristic in service.characteristics) {
        [_strData appendFormat:@"characteristic.UUID: %@\n", characteristic.UUID];
        [_strData appendFormat:@"characteristic.properties: %u\n", characteristic.properties];
        [_strData appendFormat:@"characteristic.value: ->%@<-\n", [self hexRepresentationWithSpaces_AS:characteristic.value withSpace:YES]];
        [_strData appendString:@"----------\n\n"];
    }
    [_strData appendString:@"<<<<< STOP DISCOVERY SERVICE >>>>>\n"];
    if (service == [_tmpService lastObject])
    {
        [self done];
    }
}

-(void)done
{
    DISMISS_LOADING();
    
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Input" message:@"Please enter current tempareture from EmeraldView app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [_strData appendFormat:@"\n\nCURRENT TEMPARETURE: %@", [[alertView textFieldAtIndex:0] text]];
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[@"simon.byun@appromobile.com", @"hdinguyen@gmail.com"]];
        [composeViewController setSubject:@"[BLE thermometer] Raw data collection"];
        [composeViewController setMessageBody:_strData isHTML:NO];
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:^{
        [[[UIAlertView alloc]initWithTitle:@"Sent" message:nil delegate:nil cancelButtonTitle:@"Done" otherButtonTitles: nil] show];
    }];
}

-(NSString*)hexRepresentationWithSpaces_AS:(NSData*)data withSpace:(BOOL)space
{
    const unsigned char* bytes = (const unsigned char*)[data bytes];
    NSUInteger nbBytes = [data length];
    //If spaces is true, insert a space every this many input bytes (twice this many output characters).
    static const NSUInteger spaceEveryThisManyBytes = 4UL;
    //If spaces is true, insert a line-break instead of a space every this many spaces.
    static const NSUInteger lineBreakEveryThisManySpaces = 4UL;
    const NSUInteger lineBreakEveryThisManyBytes = spaceEveryThisManyBytes * lineBreakEveryThisManySpaces;
    NSUInteger strLen = 2*nbBytes + (space ? nbBytes/spaceEveryThisManyBytes : 0);
    
    NSMutableString* hex = [[NSMutableString alloc] initWithCapacity:strLen];
    for(NSUInteger i=0; i<nbBytes; ) {
        [hex appendFormat:@"%02X", bytes[i]];
        //We need to increment here so that the every-n-bytes computations are right.
        ++i;
        
        if (space) {
            if (i % lineBreakEveryThisManyBytes == 0) [hex appendString:@"\n"];
            else if (i % spaceEveryThisManyBytes == 0) [hex appendString:@" "];
        }
    }
    return hex;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_mData count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"deviceCell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"deviceCell"];
    }
    cell.textLabel.text = [[_mData objectAtIndex:indexPath.row] name];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHOW_LOADING();
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [_centralManager connectPeripheral:[_mData objectAtIndex:indexPath.row] options:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
}
@end
