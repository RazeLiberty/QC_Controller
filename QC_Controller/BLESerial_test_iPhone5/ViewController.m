//
//  ViewController.m
//  BLESerial_test_iPhone5
//
//  Created by 石井 孝佳 on 2013/11/12.
//  Copyright (c) 2013年 浅草ギ研. All rights reserved.
//
//　ロール：ｘ軸まわりの回転、進行方向軸まわりの回転
//　ピッチ：y軸まわりの回転、上下回転
//　ヨーは、z軸まわりの回転、機体の左右回転

#import "ViewController.h"
#import "BLEBaseClass.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"

// 11/18　送信データ
#define FLIGHT_MODE_DATA    0xd1
#define EMERGENCY_STOP_DATA 0xe1

#define THROTTLE_PLUS_DATA  0x71                                   //↑
#define THROTTLE_MINUS_DATA 0x72                                   //↓
#define YAW_PLUS_DATA       0x81                                   //→
#define YAW_MINUS_DATA      0x82                                   //←
#define ROLL_PLUS_DATA      0x91                                   //D
#define ROLL_MINUS_DATA     0x92                                   //A
#define CURRENT_STOP_DATA   0x93                                   //今の位置で停まる
#define PITCH_PLUS_DATA     0x94                                   //W
#define PITCH_MINUS_DATA    0x95                                   //S

//空データ
#define EMPTY_DATA          0xc1
#define SEND_FREQUENCY      3.0f

//テキストサイズ
#define TEXT_SIZE           20

//ボタンサイズ
#define BUTTON_SIZE_X       200
#define BUTTON_SIZE_Y       10

//ボタン位置
#define BUTTON_LOCATE_X     60

//UUID
#define UUID_VSP_SERVICE    @"569a1101-b87f-490c-92cb-11ba5ea5167c"//VSP
#define UUID_RX             @"569a2001-b87f-490c-92cb-11ba5ea5167c"//RX
#define UUID_TX             @"569a2000-b87f-490c-92cb-11ba5ea5167c"//TX

@interface ViewController () <BLEDeviceClassDelegate>
@property (strong)		BLEBaseClass*	BaseClass;
@property (readwrite)	BLEDeviceClass*	Device;

@property NSDate *now;          //今の時刻
@property BOOL connectFlag;     //接続フラグ

//タッチダウン
- (IBAction)rightKeyTouchDown:(id)sender;
- (IBAction)leftKeyTouchDown:(id)sender;
- (IBAction)upKeyTouchDown:(id)sender;
- (IBAction)downKeyTouchDown:(id)sender;
- (IBAction)wKeyTouchDown:(id)sender;
- (IBAction)aKeyTouchDown:(id)sender;
- (IBAction)sKeyTouchDown:(id)sender;
- (IBAction)dKeyTouchDown:(id)sender;

//タップ
- (IBAction)connectTouchUpInside:(id)sender;
- (IBAction)disconnectTouchUpInside:(id)sender;

- (IBAction)flightModeKeyTouchUpInside:(id)sender;
- (IBAction)emergencyKeyTouchUpInside:(id)sender;

- (IBAction)rightKeyTouchUpInside:(id)sender;
- (IBAction)leftKeyTouchUpInside:(id)sender;
- (IBAction)upKeyTouchUpInside:(id)sender;
- (IBAction)downKeyTouchUpInside:(id)sender;
- (IBAction)wKeyTouchUpInside:(id)sender;
- (IBAction)aKeyTouchUpInside:(id)sender;
- (IBAction)sKeyTouchUpInside:(id)sender;
- (IBAction)dKeyTouchUpInside:(id)sender;

//ボタンステータス
@property (weak, nonatomic) IBOutlet UIButton *connectButtonStatus;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButtonStatus;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //マルチスレッド起動
    [self otherThread];
    
    _connectFlag = FALSE;   //接続フラグをFALSE
    _now = [NSDate date];    //今の時刻
    
	//AppDelegateのviewController 変数に自分(ViewController)を代入
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.viewController = self;
    
    //---センサー値結果のテキストフィールド生成---
    _textField=[[UITextField alloc] init];
    [_textField setFrame:CGRectMake(10,50,300,50)];  //位置と大きさ設定
    [_textField setText:@"OFFLINE"];
    [_textField setBackgroundColor:[UIColor whiteColor]];
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    _textField.font = [UIFont fontWithName:@"Helvetica" size:30];
    //テキストフィールドタッチ無効化
    _textField.enabled = NO;
    [self.view addSubview:_textField];

    //コネクトボタン状態セット
    _connectButtonStatus.enabled    = TRUE;
    _disconnectButtonStatus.enabled = FALSE;
    
    //	BLEBaseClassの初期化
	_BaseClass = [[BLEBaseClass alloc] init];
	//	周りのBLEデバイスからのadvertise情報のスキャンを開始する
	[_BaseClass scanDevices:nil];
	_Device = 0;
    NSLog(@"viewdidload");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//================================================================================
// マルチスレッド処理    空データを送り続ける
//================================================================================
-(void)otherThread {
    NSLog(@"ふううううううううううう");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self performSelectorInBackground:@selector(loopBackground) withObject:nil /*waitUntilDone:YES*/];
    });
}
//バックグラウンドでループ処理
-(void)loopBackground {
    NSLog(@"サブスレッド開始");
    //起動したまま待機
    while (YES) {
        
        //NSLog(@"マルチスレッド処理　通過");
        
        //接続されていれば
        while (_connectFlag) {
            
            //NSLog(@"ループ処理　通過");
            
            //３秒毎に空データ送信処理　実行
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(sendEmptyData)userInfo:nil repeats:YES];
            //3秒に一回だけ実行させる
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0f]];
        }
    }
    NSLog(@"サブスレッド終了");
}
//空データ送信
- (void)sendEmptyData {
    
    NSLog(@"３秒経ったら処理　はじめるよ");
    if (_connectFlag) {
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = EMPTY_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
        
        NSLog(@"データ送信処理　完了");
        
    }
}

//================================================================================
// readもしくはindicateもしくはnotifyにてキャラクタリスティックの値を読み込んだ時に呼ばれる
//================================================================================
- (void)didUpdateValueForCharacteristic:(BLEDeviceClass *)device Characteristic:(CBCharacteristic *)characteristic
{
	if (device == _Device)	{
		//	キャラクタリスティックを扱う為のクラスを取得し
		//	通知されたキャラクタリスティックと比較し同じであれば
		//	bufに結果を格納
        //iPhone->Device
		CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
		if (characteristic == rx)	{
            //			uint8_t*	buf = (uint8_t*)[characteristic.value bytes]; //bufに結果が入る
            //            NSLog(@"value=%@",characteristic.value);
			return;
		}
        
        //Device->iPhone
		CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
		if (characteristic == tx)	{
//            NSLog(@"Receive value=%@",characteristic.value);
            uint8_t*	buf = (uint8_t*)[characteristic.value bytes]; //bufに結果が入る
            _textField.text = [NSString stringWithFormat:@"%x", buf[0]];
			return;
		}
        
	}
}

//================================================================================
// ボタンタップイベント
//================================================================================

// CONNECT
- (IBAction)connectTouchUpInside:(id)sender{
    //connect処理呼び出す
    [self connect];
}

// DISCONNECT
- (IBAction)disconnectTouchUpInside:(id)sender {
    //disconnect処理呼び出す
    [self disconnect];
}

// EMERGENCYSTOP
- (IBAction)emergencyKeyTouchUpInside:(id)sender {
    //緊急停止処理呼び出す
    [self emergencyStop];
}


//================================================================================
// connect処理
//================================================================================
-(void)connect {
    //	UUID_DEMO_SERVICEサービスを持っているデバイスに接続する
	_Device = [_BaseClass connectService:UUID_VSP_SERVICE];
	if (_Device)	{
		//	接続されたのでスキャンを停止する
		[_BaseClass scanStop];
        //connectフラグ
        _connectFlag = TRUE;
        //	キャラクタリスティックの値を読み込んだときに自身をデリゲートに指定
		_Device.delegate = self;
        
        //        [_BaseClass printDevices];
        
        //ボタンの状態変更
        _connectButtonStatus.enabled    = FALSE;
        _disconnectButtonStatus.enabled = TRUE;
        
		//	tx(Device->iPhone)のnotifyをセット
		CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
		if (tx)	{
            //            [_Device readRequest:tx];
			[_Device notifyRequest:tx];
		}
	}
}

//================================================================================
// disconnect処理
//================================================================================
- (void)disconnect {
    //disconnectする前に緊急停止を行う
    [self emergencyStop];
    
	if (_Device)	{
		//	UUID_DEMO_SERVICEサービスを持っているデバイスから切断する
		[_BaseClass disconnectService:UUID_VSP_SERVICE];
		_Device = 0;
        //connectフラグ
        _connectFlag = FALSE;
        
        //ボタンの状態変更
        _connectButtonStatus.enabled    = TRUE;
        _disconnectButtonStatus.enabled = FALSE;
        _textField.text                 = @"OFFLINE";
         
		//	周りのBLEデバイスからのadvertise情報のスキャンを開始する
		[_BaseClass scanDevices:nil];
	}
}

//================================================================================
// 緊急停止処理
//================================================================================
- (void)emergencyStop {
    _textField.text = (@"EMERGENCY");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = EMERGENCY_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

//================================================================================
// フライトモードボタン
//================================================================================
- (IBAction)flightModeKeyTouchUpInside:(id)sender {
    _textField.text = (@"FLIGHT_MODE_ON");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = FLIGHT_MODE_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

//================================================================================
// 操作キー　タッチダウンイベント QuadCopter移動
//================================================================================
- (IBAction)rightKeyTouchDown:(id)sender {
    _textField.text = (@"YAW_PLUS");
    _connectFlag = TRUE;
    NSLog(@"接続したぜ");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = YAW_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)leftKeyTouchDown:(id)sender {
    _textField.text = (@"YAW_MINUS");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = YAW_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)upKeyTouchDown:(id)sender {
    _textField.text = (@"THROTTLE_PLUS");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = THROTTLE_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)downKeyTouchDown:(id)sender {
    _textField.text = (@"THROTTLE_MINUS");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = THROTTLE_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)wKeyTouchDown:(id)sender {
    _textField.text = (@"PITCH_PLUS");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = PITCH_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"PITCH_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)aKeyTouchDown:(id)sender {
    _textField.text = (@"ROLL_MINUS");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = ROLL_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_MINUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)sKeyTouchDown:(id)sender {
    _textField.text = (@"PITCH_MINUS");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = PITCH_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"PITCH_MINUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}

- (IBAction)dKeyTouchDown:(id)sender {
    _textField.text = (@"ROLL_PLUS");

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = ROLL_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
    
}

//================================================================================
// 操作キーを離した時の処理　　　タップ　　離した場所でQuadCopter停止処理
//================================================================================
- (IBAction)rightKeyTouchUpInside:(id)sender {
    _textField.text = (@"rightKeyTUI");
    _connectFlag = FALSE;
    NSLog(@"接続切ったぜ");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)leftKeyTouchUpInside:(id)sender {
    _textField.text = (@"leftKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)upKeyTouchUpInside:(id)sender {
    _textField.text = (@"upKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)downKeyTouchUpInside:(id)sender {
    _textField.text = (@"downKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)wKeyTouchUpInside:(id)sender {
    _textField.text = (@"wKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)aKeyTouchUpInside:(id)sender {
    _textField.text = (@"aKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)sKeyTouchUpInside:(id)sender {
    _textField.text = (@"sKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
- (IBAction)dKeyTouchUpInside:(id)sender {
    _textField.text = (@"dKeyTUI");
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
@end
