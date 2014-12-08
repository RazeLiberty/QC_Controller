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

//ボタンタグ
#define CONNECT_BUTTON      0
#define DISCONNECT_BUTTON   1

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
	// Do any additional setup after loading the view, typically from a nib.
    
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

    
    //---CONNECTボタン生成---
    _connectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_connectButton setFrame:CGRectMake(BUTTON_LOCATE_X,120,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [_connectButton setTag:CONNECT_BUTTON];           //ボタン識別タグ
    [_connectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _connectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_connectButton];
    
    
    //---DISCONNECTボタン生成---
    _disconnectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_disconnectButton setFrame:CGRectMake(BUTTON_LOCATE_X,150,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_disconnectButton setTitle:@"DIS CONNECT" forState:UIControlStateNormal];
    [_disconnectButton setTag:DISCONNECT_BUTTON];           //ボタン識別タグ
    [_disconnectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _disconnectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_disconnectButton];

    //---ボタンの状態設定---
    _connectButton.enabled          = TRUE;
    _disconnectButton.enabled       = FALSE;
    //コネクトボタン状態セット
    _connectButtonStatus.enabled    = TRUE;
    _disconnectButtonStatus.enabled = FALSE;
    
    //	BLEBaseClassの初期化
	_BaseClass = [[BLEBaseClass alloc] init];
	//	周りのBLEデバイスからのadvertise情報のスキャンを開始する
	[_BaseClass scanDevices:nil];
	_Device = 0;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
-(IBAction)onButtonClick:(UIButton*)sender{
    if(sender.tag==CONNECT_BUTTON){
        [self connect];
    }else if(sender.tag==DISCONNECT_BUTTON){
        [self disconnect];
    }
}

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
        //	キャラクタリスティックの値を読み込んだときに自身をデリゲートに指定
		_Device.delegate = self;
        
        //        [_BaseClass printDevices];
        
        //ボタンの状態変更
        _connectButton.enabled          = FALSE;
        _disconnectButton.enabled       = TRUE;
        //IBActionの方
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
	if (_Device)	{
		//	UUID_DEMO_SERVICEサービスを持っているデバイスから切断する
		[_BaseClass disconnectService:UUID_VSP_SERVICE];
		_Device = 0;
        
        //ボタンの状態変更
        _connectButton.enabled          = TRUE;
        _disconnectButton.enabled       = FALSE;
        //IBActionの方
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
        //	ダミーデータ
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
        //	ダミーデータ
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

    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
    
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
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
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = CURRENT_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
@end
