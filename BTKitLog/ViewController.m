//
//  ViewController.m
//  BTKitLog
//
//  Created by ----- on ----/--/--.
//  Copyright (c) 2014年 -----. All rights reserved.
//

//------------------------------------------------------------------------
//  対象
//  OS:iOS7.1以降
//  機種:iPad3以降
//------------------------------------------------------------------------


#import "ViewController.h"

//------------------------------------------------------------------------
//  デバイス名の設定
//------------------------------------------------------------------------

// デバイス名
#define DEVICE_NAME    @"Mul20017"

//------------------------------------------------------------------------
//  UUIDの設定
//
//  例：サービスUUID「0x56396415E301A7B4DC48CED976D324E9」 → "56396415-E301-A7B4-DC48-CED976D324E9"
//     キャラクタリスティックUUID「0x387041549A8C8F8F444989C0AF8A0402」 → "38704154-9A8C-8F8F-4449-89C0AF8A0402"
//------------------------------------------------------------------------

// サービスUUID
#define SENSOR_SERVICE_UUID    @"56396415-E301-A7B4-DC48-CED976D324E9"

// キャラクタリスティックUUID
#define SENSOR_CHARACTERISTIC_UUID  @"38704154-9A8C-8F8F-4449-89C0AF8A0402"

// socket
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface ViewController ()
@end

@implementation ViewController

// ------------------------------------------------------------------------
//  viewDidLoad
//
//  アプリ起動時の処理
// ------------------------------------------------------------------------
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // バッググラウンド処理の通知
    //   AppDelegate.mの<applicationDidEnterBackgroud>, <applicationWillEnterForeground>
    //   メソッドよりNSNotificationを介して通知を受け、バックグラウンド移行時に切断、
    //   フォアグラウンド時にスキャン処理を行う
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(applicationDidEnterBackground) name:@"applicationDidEnterBackground" object:nil];
    [nc addObserver:self selector:@selector(applicationWillEnterForeground) name:@"applicationWillEnterForeground" object:nil];
    
    // txtLogの設定
    txtLog.textAlignment = NSTextAlignmentLeft;
    txtLog.layer.borderWidth = 1;
    txtLog.layer.borderColor = [[UIColor blackColor] CGColor];
    txtLog.layer.cornerRadius = 8;
    
    // ログファイル名の初期化
    fileName = @"";
    
    // ログデータの初期化
    txtLogDat = @"";
    
    // CoreBluetoothManagerの初期化
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // Startメッセージ送信
    [self sendUdp: @"START"];

    // Bluetoothスキャン
    [self deviceScan];
}

// ------------------------------------------------------------------------
//  didReceiveMemoryWarning
//
//  メモリ不足時の処理
// ------------------------------------------------------------------------
- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    
    // 以下に記述
}

// ------------------------------------------------------------------------
//  applicationDidEnterBackground
//
//  バッググラウンド移行時の処理
// ------------------------------------------------------------------------
- (void)applicationDidEnterBackground {
    
    // 接続している場合
    if (device) {
        
        // Bluetoothを切断
        [manager cancelPeripheralConnection:device];
    }
}

// ------------------------------------------------------------------------
//  applicationWillEnterForeground
//
//  バッググラウンド復帰時の処理
// ------------------------------------------------------------------------
- (void)applicationWillEnterForeground {

    // Startメッセージ送信
    [self sendUdp: @"START"];

    // 以下に記述
    // Bluetoothスキャン
    [self deviceScan];

}

// ------------------------------------------------------------------------
//  BLEstate
//
//  Bluetoothが使用できるか状態を確認
// ------------------------------------------------------------------------
- (BOOL)BLEstate {
    
    // 状態判定
    switch ([manager state]) {
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
            return false;
            
        case CBCentralManagerStateUnauthorized:
            NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
            return false;
            
        case CBCentralManagerStatePoweredOff:
            NSLog( @"Bluetooth setting -> OFF no");
            return false;
            
        case CBCentralManagerStatePoweredOn:
            NSLog( @"Bluetooth is available to use.");
            return true;
            
        case CBCentralManagerStateUnknown:
            
        default:
            NSLog( @"Bluetooth manager start.");
            return false;
    }
}

// ------------------------------------------------------------------------
//  deviceScan
//
//  Bluetoothのスキャン処理
// ------------------------------------------------------------------------
- (void)deviceScan {
    
    // Bluetoothの状態が正常の場合
    if ([self BLEstate]) {
        
        // 一度スキャンを停止する
        [manager stopScan];
        
        // サービス設定
        NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:SENSOR_SERVICE_UUID], nil];
        
        // オプション設定
        NSDictionary *option = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        
        // Bluetoothスキャン開始
        [manager scanForPeripheralsWithServices:services options:option];
        
        NSLog(@"scan");
    }
}

// ------------------------------------------------------------------------
//  centralManagerDidUpdateState
//
//  CBCentralManagerの状態変化後の処理
// ------------------------------------------------------------------------
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    // 状態判定
    switch (central.state) {
            
        case CBCentralManagerStatePoweredOn:
            NSLog(@"centralManagerDidUpdateState poweredOn");
            [self deviceScan];
            break;
            
        case CBCentralManagerStatePoweredOff:
            NSLog(@"centralManagerDidUpdateState poweredOff");
            [self cleanup];
            break;
            
        case CBCentralManagerStateResetting:
            NSLog(@"centralManagerDidUpdateState resetting");
            [self cleanup];
            break;
            
        case CBCentralManagerStateUnauthorized:
            NSLog(@"centralManagerDidUpdateState unauthorized");
            [self cleanup];
            break;
            
        case CBCentralManagerStateUnsupported:
            NSLog(@"centralManagerDidUpdateState unsupported");
            [self cleanup];
            break;
            
        case CBCentralManagerStateUnknown:
            NSLog(@"centralManagerDidUpdateState unknown");
            [self cleanup];
            break;
            
        default:
            break;
    }
}

// ------------------------------------------------------------------------
//  cleanup
//
//  各設定の初期化
// ------------------------------------------------------------------------
- (void)cleanup {
    
    // デバイス設定のリセット
    if (device) {
        
        device.delegate = nil;
        device = nil;
    }
    
    // ログファイルを閉じる
    [self closeFile];
    
    NSLog(@"cleanup");

    // Bluetoothスキャン
    [self deviceScan];
}

// ------------------------------------------------------------------------
//  centralManager(didDiscoverPeripheral)
//
//  Bluetoothスキャン時の処理
// ------------------------------------------------------------------------
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //　advertisementDataのサービスを取得
    NSArray *services = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    
    // 設定したサービスと一致した場合
    if ([services containsObject:[CBUUID UUIDWithString:SENSOR_SERVICE_UUID]]) {
        
        // スキャンしたデバイス名を取得
        NSString* findName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        
        // 設定したデバイス名(DEVICE_NAME)のみ接続
        // （センサーが変わる場合、先頭行のdefineで定義されているDEVICE_NAMEの文字を変更してください）
        if ([findName isEqualToString:DEVICE_NAME]) {
            
            // Bluetoothスキャン停止
            [manager stopScan];
            
            // デバイス設定
            device = aPeripheral;
            
            // オプション設定
            NSDictionary *option = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnConnectionKey];
            
            // Bluetooth接続処理の開始
            [manager connectPeripheral:device options:option];
            NSLog(@"didDiscoverPeripheral:%@", findName);
        }
    }
}

// ------------------------------------------------------------------------
//  setNotifyValueForService
//
//  Notifyの設定
// ------------------------------------------------------------------------
- (void)setNotifyValueForService:(NSString*)serviceUUIDStr characteristicUUID:(NSString*)characteristicUUIDStr peripheral:(CBPeripheral *)aPeripheral enable:(bool)enable {
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:serviceUUIDStr];
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:characteristicUUIDStr];
    
    // サービス取得
    CBService *service = [self findServiceFromUUID:serviceUUID peripheral:aPeripheral];
    
    if (!service) {
        
        NSLog(@"Could not find service with UUID %@", serviceUUIDStr);
        return;
    }
    
    // キャラクタリスティック取得
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];
    
    if (!characteristic) {
        
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ ", characteristicUUIDStr, serviceUUIDStr);
        return;
    }
    
    for (characteristic in service.characteristics) {
        
        // キャラクタリスティックUUIDが一致し、Notifyが現在の状態から変更される場合
        if ([characteristic.UUID isEqual:characteristicUUID] && enable != characteristic.isNotifying) {

            // Notify設定
            [aPeripheral setNotifyValue:enable forCharacteristic:characteristic];
            
            if (enable) NSLog(@"notifyOn");
            else if (enable) NSLog(@"notifyOff");
        }
    }
}

// ------------------------------------------------------------------------
//  findServiceFromUUID
//
//  Serviceの検索
// ------------------------------------------------------------------------
- (CBService *) findServiceFromUUID:(CBUUID *)UUID peripheral:(CBPeripheral *)aPeripheral {
    
    for (int i = 0; i < aPeripheral.services.count; i++) {
        
        CBService *service = [aPeripheral.services objectAtIndex:i];
        if ([UUID isEqual:service.UUID]) return service;
    }
    
    return nil;
}

// ------------------------------------------------------------------------
//  findCharacteristicFromUUID
//
//  Characteristicの検索
// ------------------------------------------------------------------------
- (CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    
    for (int i = 0; i < service.characteristics.count; i++) {
        
        CBCharacteristic *characteristic = [service.characteristics objectAtIndex:i];
        if ([UUID isEqual:characteristic.UUID]) return characteristic;
    }
    
    return nil;
}

// ------------------------------------------------------------------------
//  peripheral(didDiscoverServices)
//
//  Service検索完了後の処理
// ------------------------------------------------------------------------
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error {
    
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        return;
    }
    
    for (CBService *aService in aPeripheral.services) {
        
        // 設定したサービスと一致した場合
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:SENSOR_SERVICE_UUID]]) {
            
            // キャラクタリスティックの検索を開始
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

// ------------------------------------------------------------------------
//  peripheral(didDiscoverCharacteristicsForService)
//
//  Characteristics検索完了後の処理
// ------------------------------------------------------------------------
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (error) {
        NSLog(@"chara error : %@", [error localizedDescription]);
        return;
    }
    
    // 設定したサービスと一致した場合
    if ([service.UUID isEqual:[CBUUID UUIDWithString:SENSOR_SERVICE_UUID]]) {
        
        for (CBCharacteristic *aChar in service.characteristics) {
            
            // 設定したキャラクタリスティックと一致した場合
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:SENSOR_CHARACTERISTIC_UUID]]) {
                    
                // Notify有効化
                [self setNotifyValueForService:SENSOR_SERVICE_UUID characteristicUUID:SENSOR_CHARACTERISTIC_UUID peripheral:device enable:YES];
                
                // ログファイル作成
                [self createFile];
            }
        }
    }
}

// ------------------------------------------------------------------------
//  centralManager(didConnectPeripheral)
//
//  Bluetooth接続後の処理
// ------------------------------------------------------------------------
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral {
    
    NSLog(@"connected");
    
    // デリゲート設定
    [device setDelegate:self];
    
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:SENSOR_SERVICE_UUID], nil];
    
    // サービス検索
    [device discoverServices:services];
}

// ------------------------------------------------------------------------
//  centralManager(didDisconnectPeripheral)
//
//  Bluetooth切断後の処理
// ------------------------------------------------------------------------
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error {
    
    NSLog(@"disConnected");

    [self cleanup];
}

// ------------------------------------------------------------------------
//  centralManager(didFailToConnectPeripheral)
//
//  Bluetooth接続失敗時の処理
// ------------------------------------------------------------------------
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error {

    NSLog(@"FailToConnected");
    
    [self cleanup];
}

// ------------------------------------------------------------------------
//  peripheral(didUpdateValueForCharacteristic)
//
//  Bluetoothデータ更新時の処理
// ------------------------------------------------------------------------
- (void)peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if (error) {
        
        NSLog(@"didUpdateValueForCharacteristic error: %@", error.localizedDescription);
        return;
    }
    
    // 接続頻度を緩和
    NSDate *time = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"ss.S";
    NSString *currentSecond = [fmt stringFromDate:time];
    NSLog(@"currentSecond: %@", currentSecond);
    if ([currentSecond isEqual: lastSecond]) {
        lastSecond = currentSecond;
        return;
    }
    lastSecond = currentSecond;

    
    // 設定したキャラクタリスティックと一致し、長さが１以上の場合
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SENSOR_CHARACTERISTIC_UUID]] && characteristic.value.length > 0) {

        // 受信したデータを配列に代入
        UInt8 *dat = (UInt8*) [characteristic.value bytes];
        
        // 以下、データ処理部分（受信するデータのフォーマットに応じて変更）-----------------------------------
        
        // ヘッダーチェック
        if (dat[0] != 0x14) return;
        
        // データチェック
        if ((dat[2]+dat[3]+dat[4]+dat[5]+dat[6]+dat[7]) != 0) {
            
            // 地磁気
            SInt16 rawMx = (dat[3] << 8) | dat[2];
            SInt16 rawMy = (dat[5] << 8) | dat[4];
            SInt16 rawMz = (dat[7] << 8) | dat[6];
            
            // 値制限
            if (rawMx > 16000) rawMx = 16000;
            else if (rawMx < -16000) rawMx = -16000;
            if (rawMy > 16000) rawMy = 16000;
            else if (rawMy < -16000) rawMy = -16000;
            if (rawMz > 16000) rawMz = 16000;
            else if (rawMz < -16000) rawMz = -16000;
            
            datMx = (float)rawMx * 0.15f;
            datMy = (float)rawMy * 0.15f;
            datMz = (float)rawMz * 0.15f;

            // 四捨五入
            datMx = roundf(datMx);
            datMy = roundf(datMy);
            datMz = roundf(datMz);

            //「-0.0」を「0.0」にする
            if (!datMx) datMx = 0;
            if (!datMy) datMy = 0;
            if (!datMz) datMz = 0;
            
            // 加速度
            SInt16 rawAx = (dat[9] << 8) | dat[8];
            SInt16 rawAy = (dat[11] << 8) | dat[10];
            SInt16 rawAz = (dat[13] << 8) | dat[12];
            
            // 値制限
            if (rawAx > 8191) rawAx = 8191;
            else if (rawAx < -8192) rawAx = -8192;
            if (rawAy > 8191) rawAy = 8191;
            else if (rawAy < -8192) rawAy = -8192;
            if (rawAz > 8191) rawAz = 8191;
            else if (rawAz < -8192) rawAz = -8192;
            
            datAx = (float)rawAx / 1024.0f;
            datAy = (float)rawAy / 1024.0f;
            datAz = (float)rawAz / 1024.0f;
            
            // 小数点第三位を四捨五入
            datAx *= 100.0f;
            datAy *= 100.0f;
            datAz *= 100.0f;
            
            datAx = roundf(datAx);
            datAy = roundf(datAy);
            datAz = roundf(datAz);
            
            datAx /= 100.0f;
            datAy /= 100.0f;
            datAz /= 100.0f;
            
            //「-0.0」を「0.0」にする
            if (!datAx) datAx = 0;
            if (!datAy) datAy = 0;
            if (!datAz) datAz = 0;
        }
        
        if (dat[1] == 0xb0) {
            
            // UV・照度
            SInt16 rawUv = (dat[17] << 8) | dat[16];
            SInt16 rawLx = (dat[19] << 8) | dat[18];
            
            // 値制限
            if (rawUv > 4095) rawUv = 4095;
            else if (rawUv < 0) rawUv = 0;
            if (rawLx > 4095) rawLx = 4095;
            else if (rawLx < 0) rawLx = 0;
            
            datUv = (float)rawUv / 200.0f;
            datLx = (float)rawLx * 20.0f;
            
            // 小数点第三位を四捨五入
            datUv *= 100.0f;
            
            datUv = roundf(datUv);
            
            datUv /= 100.0f;
            
            // 四捨五入
            datLx = roundf(datLx);
            
            //「-0.0」を「0.0」にする
            if (!datUv) datUv = 0;
            if (!datLx) datLx = 0;
        }
        else if (dat[1] == 0xb1) {
            
            // 湿度・温度
            SInt16 rawHm = (dat[17] << 8) | dat[16];
            SInt16 rawTm = (dat[19] << 8) | dat[18];
            
            // 値制限
            if (rawHm > 7296) rawHm = 7296;
            else if (rawHm < 896) rawHm = 896;
            if (rawTm > 6346) rawTm = 6346;
            else if (rawTm < 96) rawTm = 96;
            
            datHm = ((float)rawHm - 896.0f) / 64.0f;
            datTm = ((float)rawTm - 2096.0f) / 50.0f;
            
            // 小数点第ニ位を四捨五入
            datHm *= 10.0f;
            datTm *= 10.0f;
            
            datHm = roundf(datHm);
            datTm = roundf(datTm);
            
            datHm /= 10.0f;
            datTm /= 10.0f;
            
            //「-0.0」を「0.0」にする
            if (!datHm) datHm = 0;
            if (!datTm) datTm = 0;
        }
        
        // 気圧
        UInt16 rawPs = (dat[15] << 8) | dat[14];
        
        // 値制限
        if (rawPs > 64773) rawPs = 64773;
        else if (rawPs < 3810) rawPs = 3810;
        
        datPs =  ((float)rawPs * 860.0f) / 65535.0f + 250.0f;
        
        // 小数点第三位を四捨五入
        datPs *= 100.0f;
        
        datPs = roundf(datPs);
        
        datPs /= 100.0f;
        
        // ログデータ書き込み処理
        [self LogOutput];

        // darumaサーバへUDPで送信
        [self sendUdp: [NSString stringWithFormat:@"|%d,%.0f,%.0f,%.0f,%.2f,%.2f,%.2f,%.2f|\n", datCnt, datMx, datMy, datMz, datAx, datAy, datAz, datPs]];
        
        // darumaサーバへ送信
        // [self sendToDaruma];
        
        // データ処理終了-----------------------------------------------------------------------------------
    }
}

// ------------------------------------------------------------------------
//  LogOutput
//
//　ログデータ書き込み処理
// ------------------------------------------------------------------------
- (void)LogOutput {

    // 現在時刻取得
    NSDate *time = [NSDate date];

    // 時刻をフォーマット
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss.SSS";
    NSString *dateTime = [fmt stringFromDate:time];
    
    // データカウント
    datCnt++;
    datDispCnt++;

    // ログデータ設定
//    NSString *logDat = [NSString stringWithFormat:@"%6d, %5.0f, %5.0f, %5.0f,  %4.1f, %4.1f, %4.1f, %6.2f, %6.0f, %6.1f, %6.1f, %8.2f,  %@\n", datCnt, datMx, datMy, datMz, datAx, datAy, datAz, datUv, datLx, datHm, datTm, datPs, dateTime];
    
    NSString *logDat = [NSString stringWithFormat:@"Count:\t%6d\nMagX:\t%5.0f\nMagY:\t%5.0f\nMagZ:\t%5.0f\nAccX:\t%4.1f\nAccY:\t%4.1f\nAccZ:\t%4.1f\nPs:\t%8.2f\nTime:\t%@\n", datCnt, datMx, datMy, datMz, datAx, datAy, datAz, datPs, dateTime];

    
    // 前のログデータに追加
//    txtLogDat = [txtLogDat stringByAppendingString:logDat];

    // 画面に表示
//    txtLog.text = txtLogDat;
    txtLog.text = logDat;

    // 現在表示しているデータが30行以上の場合
    if (datDispCnt >= 30) {
        
        // 行数をリセット
        datDispCnt = 0;
        
        // データをリセット
        txtLogDat = @"";
    }

    // ファイルハンドルが有効の場合
    if (fileHandle) {

        // ファイルへの書き込み
        logDat = [NSString stringWithFormat:@"%@", [logDat stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];

        NSData *logDatE = [logDat dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES];
        [fileHandle writeData:logDatE];
    }
    
    // データ数が65,533以上の場合
    if (datCnt >= 65533) {
        
        // ログファイルを閉じる
        [self closeFile];
        
        // 新規ファイル作成
        [self createFile];
    }
}

- (void)sendUdp:(NSString *)text {
    CFSocketRef socket = CFSocketCreate(NULL, PF_INET, SOCK_DGRAM, IPPROTO_UDP, kCFSocketNoCallBack, NULL, NULL);
    
    struct sockaddr_in addr;
    addr.sin_len = sizeof(struct sockaddr_in);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr("172.20.10.2");
    addr.sin_port = htons(10001);
    CFDataRef address = CFDataCreate(NULL, (UInt8*)&addr, sizeof(struct sockaddr_in));
    NSData *messageData = [text dataUsingEncoding:NSUTF8StringEncoding];
//    NSData *messageData = [@"SOME STRING VALUE" dataUsingEncoding:NSUTF8StringEncoding];
    const void *bytes = [messageData bytes];
    // int length = [messageData length];
    uint8_t *message = (uint8_t*)bytes;

    CFDataRef data = CFDataCreate(NULL, (UInt8*)message, strlen(message));
    CFSocketSendData(socket, address, data, 3);
    CFRelease(socket);
    CFRelease(address);
    CFRelease(data);
    NSLog(@"udp");
}

- (void)sendToDaruma {
    
    NSString *urlString = [NSString stringWithFormat:@"http://172.20.10.2:4567/set?mx=%.0f&my=%.0f&mz=%.0f&ax=%.1f&ay=%.1f&az=%.1f&ps=%.2f", datMx, datMy, datMz, datAx, datAy, datAz, datPs];

    NSLog(@"urlString = %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSLog(@"error = %@", error);
    NSLog(@"statusCode = %d", ((NSHTTPURLResponse *)response).statusCode);
    NSLog(@"responseText = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}


// ------------------------------------------------------------------------
//  createFile
//
//　ログファイルの作成処理
//  *作成されたファイルはiTunesのファイル共有でPCに転送可能
//  （iPadをPCに接続して「iTunes」→「iPad」→「App」→「ファイル共有」→「書類」から転送）
// ------------------------------------------------------------------------
- (void)createFile {
    
    // 現在時刻取得
    NSDateFormatter *formatter;
    formatter=[[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyMMdd-HHmmss-"];
    
    // ファイル名設定
    NSString *strDate = [formatter stringFromDate:[NSDate date]];
    fileName = [strDate stringByAppendingString:@"log.csv"];
    lblLogFileName.text = [@"出力ファイル名:  " stringByAppendingString:fileName];
    
    // アプリのDocumentsフォルダのパス取得
    NSString *homeDir  = NSHomeDirectory();
    NSString *fileDir  = [homeDir stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [fileDir stringByAppendingPathComponent:fileName];
    
    // ディレクトリ設定
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // ヘッダー設定
    NSString *header = @",Magnetic Field,,,Acceleration,,,,,,,,\n";
    NSString *header2 = @"No,X,Y,Z,X,Y,Z,UV-A,AmbientLight,Humidity,Temperature,Pressure,Time\n";
    header = [header stringByAppendingString:header2];
    NSData *datHeader = [header dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES];
    
    // ファイル作成
    [fileManager createFileAtPath:filePath contents:datHeader attributes:nil];
    
    // ファイルハンドル
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    // ファイルハンドルが無効の場合
    if (!fileHandle) {
        
        NSLog(@"fileHandle Error");
        
        // ログファイルを閉じる
        [self closeFile];
        return;
    }
    
    // 書き込み位置をファイルの末尾に移動する
    [fileHandle seekToEndOfFile];
}

// ------------------------------------------------------------------------
//  closeFile
//
//　ログファイルの終了処理
// ------------------------------------------------------------------------
- (void)closeFile {
    
    // データカウントのリセット
    datCnt = 0;
    datDispCnt = 0;
    
    // ログデータの初期化
    txtLogDat = @"";
    
    // ファイルハンドルが有効の場合
    if (fileHandle) {
        
        // ログファイルを閉じる
        [fileHandle closeFile];
        fileHandle = nil;
    }
}

@end


// Made by NUMATA R&D Co Ltd 2014