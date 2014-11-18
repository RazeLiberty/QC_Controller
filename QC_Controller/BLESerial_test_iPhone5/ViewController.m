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
#define CONNECT_BUTTON 0
#define DISCONNECT_BUTTON 1
/*
 //ボタンタグ
 #define CONNECT_BUTTON 0
 #define DISCONNECT_BUTTON 1
 #define FLIGHT_MODE_BUTTON 2
 #define EMERGENCY_STOP_BUTTON 3
 #define DEFAULT_BUTTON 4
 #define THROTTLE_BUTTON 5
 #define THROTTLE_PLUS_BUTTON 6
 #define THROTTLE_MINUS_BUTTON 7
 #define ROLL_BUTTON 8
 #define ROLL_PLUS_BUTTON 9
 #define ROLL_MINUS_BUTTON 10
 #define PITCH_BUTTON 11
 #define PITCH_PLUS_BUTTON 12
 #define PITCH_MINUS_BUTTON 13
 #define YAW_BUTTON 14
 #define YAW_PLUS_BUTTON 15
 #define YAW_MINUS_BUTTON 16
*/

/* 前の送信データ
 //送るデータ
 #define FLIGHT_MODE_DATA 0xd1
 #define EMERGENCY_STOP_DATA 0xe1
 #define DEFAULT_VALUE_DATA 0xe1
 #define THROTTLE_DATA 0xe1
 #define THROTTLE_PLUS_DATA 0x71
 #define THROTTLE_MINUS_DATA 0x72
 #define ROLL_DATA 0x20
 #define PITCH_DATA 0x30
 #define YAW_DATA 0x40
 #define YAW_PLUS_DATA 0x81
 #define YAW_MINUS_DATA 0x82
 */

// 11/18　送信データ
#define FLIGHT_MODE_DATA 0xd1
#define EMERGENCY_STOP_DATA 0xe1
//#define DEFAULT_VALUE_DATA 0xe1
//#define THROTTLE_DATA 0xe1
#define THROTTLE_PLUS_DATA 0x71 //↑
#define THROTTLE_MINUS_DATA 0x72//↓
#define YAW_PLUS_DATA 0x81      //→
#define YAW_MINUS_DATA 0x82     //←
//#define ROLL_DATA 0x20
#define ROLL_PLUS_DATA 0x91     //D
#define ROLL_MINUS_DATA 0x92    //A
#define CURRENT_STOP_DATA 0x93  //今の位置で停まる
#define PITCH_PLUS_DATA 0x94    //W
#define PITCH_MINUS_DATA 0x95   //S
//#define PITCH_DATA 0x30
//#define YAW_DATA 0x40


//テキストサイズ
#define TEXT_SIZE 20

//ボタンサイズ
#define BUTTON_SIZE_X 200
#define BUTTON_SIZE_Y 10

//ボタン位置
#define BUTTON_LOCATE_X 60



//UUID
#define UUID_VSP_SERVICE					@"569a1101-b87f-490c-92cb-11ba5ea5167c" //VSP
#define UUID_RX                             @"569a2001-b87f-490c-92cb-11ba5ea5167c" //RX
#define UUID_TX								@"569a2000-b87f-490c-92cb-11ba5ea5167c" //TX

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

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    /*
    //ボタン画像生成
    _key_w = [UIImage imageNamed:@"key_w.png"];
    _key_a = [UIImage imageNamed:@"key_a.png"];
    _key_s = [UIImage imageNamed:@"key_s.png"];
    _key_d = [UIImage imageNamed:@"key_d.png"];
    _key_up = [UIImage imageNamed:@"key_up.png"];
    _key_down = [UIImage imageNamed:@"key_down.png"];
    _key_right = [UIImage imageNamed:@"key_right.png"];
    _key_left = [UIImage imageNamed:@"key_left.png"];
   
    _key_w = [UIImage imageNamed:@"key_w.png"];
*/

    
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
    
    //------------------------------------------------------------------------------------------
    //	ストーリーボード使わないなら　/**/はずす
    //------------------------------------------------------------------------------------------
    
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
    /*
    //---FLIGHT MODEボタン生成---
    _flightModeButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_flightModeButton setFrame:CGRectMake(BUTTON_LOCATE_X,180,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_flightModeButton setTitle:@"FLIGHT MODE" forState:UIControlStateNormal];
    [_flightModeButton setTag:FLIGHT_MODE_BUTTON];           //ボタン識別タグ
    [_flightModeButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _flightModeButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_flightModeButton];
    
    //---EMERGENCY STOPボタン生成---
    _emergencyStopButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_emergencyStopButton setFrame:CGRectMake(BUTTON_LOCATE_X,210,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_emergencyStopButton setTitle:@"EMERGENCY" forState:UIControlStateNormal];
    [_emergencyStopButton setTag:EMERGENCY_STOP_BUTTON];           //ボタン識別タグ
    [_emergencyStopButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _emergencyStopButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_emergencyStopButton];

    //---初期値ボタン生成---
    _defaultButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_defaultButton setFrame:CGRectMake(BUTTON_LOCATE_X,240,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_defaultButton setTitle:@"DEFAULT" forState:UIControlStateNormal];
    [_defaultButton setTag:DEFAULT_BUTTON];           //ボタン識別タグ
    [_defaultButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _defaultButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_defaultButton];

    //---スロットルボタン生成---
    _throttleButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_throttleButton setFrame:CGRectMake(BUTTON_LOCATE_X,270,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_throttleButton setTitle:@"THROTTLE" forState:UIControlStateNormal];
    [_throttleButton setTag:THROTTLE_BUTTON];           //ボタン識別タグ
    [_throttleButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _throttleButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_throttleButton];
    
    //---スロットル＋２ボタン生成---
    _throttlePlusButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_throttlePlusButton setFrame:CGRectMake(BUTTON_LOCATE_X,300,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_throttlePlusButton setTitle:@"THROTTLE_PLUS" forState:UIControlStateNormal];
    [_throttlePlusButton setTag:THROTTLE_PLUS_BUTTON];           //ボタン識別タグ
    [_throttlePlusButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _throttlePlusButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_throttlePlusButton];
    
    //---スロットルー２ボタン生成---
    _throttleMinusButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_throttleMinusButton setFrame:CGRectMake(BUTTON_LOCATE_X,330,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_throttleMinusButton setTitle:@"THROTTLE_MINUS" forState:UIControlStateNormal];
    [_throttleMinusButton setTag:THROTTLE_MINUS_BUTTON];           //ボタン識別タグ
    [_throttleMinusButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _throttleMinusButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_throttleMinusButton];
    
    //---ロールボタン生成---
    _rollButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_rollButton setFrame:CGRectMake(BUTTON_LOCATE_X,360,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_rollButton setTitle:@"ROLL" forState:UIControlStateNormal];
    [_rollButton setTag:ROLL_BUTTON];           //ボタン識別タグ
    [_rollButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリック_defaultButton登録
    _rollButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_rollButton];
    
    //---ピッチボタン生成---
    _pitchButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_pitchButton setFrame:CGRectMake(BUTTON_LOCATE_X,390,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_pitchButton setTitle:@"PITCH" forState:UIControlStateNormal];
    [_pitchButton setTag:PITCH_BUTTON];           //ボタン識別タグ
    [_pitchButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _pitchButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_pitchButton];
    
    //---ヨーボタン生成---
    _yawButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_yawButton setFrame:CGRectMake(BUTTON_LOCATE_X,420,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_yawButton setTitle:@"YAW" forState:UIControlStateNormal];
    [_yawButton setTag:YAW_BUTTON];           //ボタン識別タグ
    [_yawButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _yawButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_yawButton];
    
    //---ヨー＋２ボタン生成---
    _yawPlusButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_yawPlusButton setFrame:CGRectMake(BUTTON_LOCATE_X,450,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_yawPlusButton setTitle:@"YAW_PLUS" forState:UIControlStateNormal];
    [_yawPlusButton setTag:YAW_PLUS_BUTTON];           //ボタン識別タグ
    [_yawPlusButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _yawPlusButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_yawPlusButton];
    
    //---ヨー-２ボタン生成---
    _yawMinusButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_yawMinusButton
     setFrame:CGRectMake(BUTTON_LOCATE_X,480,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_yawMinusButton setTitle:@"YAW_MINUS" forState:UIControlStateNormal];
    [_yawMinusButton setTag:YAW_MINUS_BUTTON];           //ボタン識別タグ
    [_yawMinusButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _yawMinusButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_yawMinusButton];
    */
    //---ボタンの状態設定---
    _connectButton.enabled = TRUE;
    _disconnectButton.enabled = FALSE;
  /*  _flightModeButton.enabled = FALSE;
    _emergencyStopButton.enabled = FALSE;
    _defaultButton.enabled = FALSE;
    _throttleButton.enabled = FALSE;
    _throttlePlusButton.enabled = FALSE;
    _throttleMinusButton.enabled = FALSE;
    _rollButton.enabled = FALSE;
    _pitchButton.enabled = FALSE;
    _yawButton.enabled = FALSE;
    _yawPlusButton.enabled = TRUE;
    _yawMinusButton.enabled = FALSE;
    */
    
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



//------------------------------------------------------------------------------------------
//	readもしくはindicateもしくはnotifyにてキャラクタリスティックの値を読み込んだ時に呼ばれる
//------------------------------------------------------------------------------------------
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

//////////////////////////////////////////////////////////////
//  ボタンクリックイベント
//////////////////////////////////////////////////////////////
-(IBAction)onButtonClick:(UIButton*)sender{
    if(sender.tag==CONNECT_BUTTON){
        [self connect];
    }else if(sender.tag==DISCONNECT_BUTTON){
        [self disconnect];
/*    }else if(sender.tag==FLIGHT_MODE_BUTTON){
        [self flightModeOn];
    }else if(sender.tag==EMERGENCY_STOP_BUTTON){
        [self emergencyStop];
    }else if(sender.tag==DEFAULT_BUTTON){
        [self defaultValue];
    }else if(sender.tag==THROTTLE_BUTTON){
        [self throttle];
    }else if(sender.tag==THROTTLE_PLUS_BUTTON){
        [self throttlePlus];
    }else if(sender.tag==THROTTLE_MINUS_BUTTON){
        [self throttleMinus];
    }else if(sender.tag==ROLL_BUTTON){
        [self roll];
    }else if(sender.tag==PITCH_BUTTON){
        [self pitch];
    }else if(sender.tag==YAW_BUTTON){
        [self yaw];
    }else if(sender.tag==YAW_PLUS_BUTTON){
        [self yawPlus];
    }else if(sender.tag==YAW_MINUS_BUTTON){
        [self yawMinus];
 */   }
}



//////////////////////////////////////////////////////////////
//  connect
//////////////////////////////////////////////////////////////
-(void)connect{
    //	UUID_DEMO_SERVICEサービスを持っているデバイスに接続する
	_Device = [_BaseClass connectService:UUID_VSP_SERVICE];
	if (_Device)	{
		//	接続されたのでスキャンを停止する
		[_BaseClass scanStop];
        //	キャラクタリスティックの値を読み込んだときに自身をデリゲートに指定
		_Device.delegate = self;
        
        //        [_BaseClass printDevices];
        
        //ボタンの状態変更
		_connectButton.enabled = FALSE;
		_disconnectButton.enabled = TRUE;
        /*
        _flightModeButton.enabled = TRUE;
        _emergencyStopButton.enabled = TRUE;
        _defaultButton.enabled = TRUE;
        _throttleButton.enabled = TRUE;
        _throttlePlusButton.enabled = TRUE;
        _throttleMinusButton.enabled = TRUE;
        _rollButton.enabled = TRUE;
        _pitchButton.enabled = TRUE;
        _yawButton.enabled = TRUE;
        _yawPlusButton.enabled = TRUE;
        _yawMinusButton.enabled = TRUE;
        _textField.text = @"ONLINE";
        */
		//	tx(Device->iPhone)のnotifyをセット
		CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
		if (tx)	{
            //            [_Device readRequest:tx];
			[_Device notifyRequest:tx];
		}
	}
}

//------------------------------------------------------------------------------------------
//	disconnectボタンを押したとき
//------------------------------------------------------------------------------------------
- (void)disconnect {
	if (_Device)	{
		//	UUID_DEMO_SERVICEサービスを持っているデバイスから切断する
		[_BaseClass disconnectService:UUID_VSP_SERVICE];
		_Device = 0;
        
        //ボタンの状態変更
		_connectButton.enabled = TRUE;
		_disconnectButton.enabled = FALSE;
        /*
        _flightModeButton.enabled = FALSE;
        _emergencyStopButton.enabled = FALSE;
        _defaultButton.enabled = FALSE;
        _throttleButton.enabled = FALSE;
        _throttlePlusButton.enabled = FALSE;
        _throttleMinusButton.enabled = FALSE;
        _rollButton.enabled = FALSE;
        _pitchButton.enabled = FALSE;
        _yawButton.enabled = FALSE;
        _yawPlusButton.enabled = FALSE;
        _yawMinusButton.enabled = FALSE;
         */
		_textField.text = @"OFFLINE";
         
		//	周りのBLEデバイスからのadvertise情報のスキャンを開始する
		[_BaseClass scanDevices:nil];
	}
}

/*
//================================================================================
// フライトモード　ONコマンド
//================================================================================

-(void)flightModeOn{
    if (_Device)	{
		//	iPhone->Device
		CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
		//	ダミーデータ
        uint8_t	buf[1];
        buf[0] = FLIGHT_MODE_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"FLIGHT_MODE_ON");
		[_Device writeWithoutResponse:rx value:data];
	}
}

//================================================================================
// 緊急停止　コマンド
//================================================================================
-(void)emergencyStop{
    if (_Device)	{
		//	iPhone->Device
		CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
		//	ダミーデータ
        uint8_t	buf[1];
        buf[0] = EMERGENCY_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"EMERGENCY_STOP");
		[_Device writeWithoutResponse:rx value:data];
	}
}

//================================================================================
// 初期値　コマンド　（ストップ）
//================================================================================
-(void)defaultValue{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = DEFAULT_VALUE_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"DEFAULT_VALUE");
        [_Device writeWithoutResponse:rx value:data];
    }
}

//================================================================================
// スロットル　コマンド
//================================================================================
-(void)throttle{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = THROTTLE_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"THROTTLE");
        [_Device writeWithoutResponse:rx value:data];
    }
}


//================================================================================
// スロットルプラス　コマンド
//================================================================================
-(void)throttlePlus{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = THROTTLE_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"THROTTLE_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}


//================================================================================
// スロットルマイナス　コマンド
//================================================================================

-(void)throttleMinus{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = THROTTLE_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"THROTTLE_MINUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}


//================================================================================
// ロール　コマンド
//================================================================================
-(void)roll{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = ROLL_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"ROLL");
        [_Device writeWithoutResponse:rx value:data];
    }
}


//================================================================================
// ピッチ　コマンド
//================================================================================
-(void)pitch{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = PITCH_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"PITCH");
        [_Device writeWithoutResponse:rx value:data];
    }
}


//================================================================================
// ヨー　コマンド
//================================================================================
-(void)yaw{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = YAW_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"YAW");
        [_Device writeWithoutResponse:rx value:data];
    }
}

//================================================================================
// ヨープラス　コマンド
//================================================================================
-(void)yawPlus{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = YAW_PLUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        _textField.text = (@"YAW_PLUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}

//================================================================================
// ヨーマイナス　コマンド
//================================================================================
-(void)yawMinus{
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	ダミーデータ
        uint8_t	buf[1];
        buf[0] = YAW_MINUS_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        //_textField.text = (@"YAW_MINUS");
        [_Device writeWithoutResponse:rx value:data];
    }
}
*/
//================================================================================
// ストーリーボード使ったなら
//================================================================================




//================================================================================
// タッチダウン　操作ボタン
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
// タップ
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

- (IBAction)emergencyKeyTouchUpInside:(id)sender {
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
// タップ　そこで停める処理
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
