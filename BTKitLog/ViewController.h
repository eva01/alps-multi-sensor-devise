//
//  ViewController.h
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


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate> {
    
    // CentralManager
    CBCentralManager    *manager;
    
    // Peripheral
    CBPeripheral    *device;
    
    // fileHandle
    NSFileHandle* fileHandle;
    
    // ログファイル名
    NSString *fileName;
    
    // ログデータ
    NSString *txtLogDat;
    
    // ログデータ数
    int datCnt;
    
    // 画面に表示しているログデータの行数
    int datDispCnt;
    
    // ログデータ用の変数
    float datMx, datMy, datMz;
    float datAx, datAy, datAz;
    float datUv, datLx;
    float datHm, datTm;
    float datPs;
    
    // ログ表示用のテキスト
    __weak IBOutlet UITextView *txtLog;
    
    // ファイル名表示用のラベル
    __weak IBOutlet UILabel *lblLogFileName;
    
    // sleep
    NSString *lastSecond;
    
}

@end