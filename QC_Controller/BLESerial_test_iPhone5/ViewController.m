//
//  ViewController.m
//  BLESerial_test_iPhone5
//
//  Created by 石井 孝佳 on 2013/11/12.
//  Copyright (c) 2013年 浅草ギ研. All rights reserved.
//

#import "ViewController.h"
#import "BLEBaseClass.h"
#import <CoreBluetooth/CoreBluetooth.h>

//ボタンタグ
#define CONNECT_BUTTON 0
#define DISCONNECT_BUTTON 1
#define FLIGHT_MODE_BUTTON 2
#define EMERGENCY_STOP_BUTTON 3

//送るデータ
#define FLIGHT_MODE_DATA 0xd1
#define EMERGENCY_STOP_DATA 0xe1

//UUID
#define UUID_VSP_SERVICE					@"569a1101-b87f-490c-92cb-11ba5ea5167c" //VSP
#define UUID_RX                             @"569a2001-b87f-490c-92cb-11ba5ea5167c" //RX
#define UUID_TX								@"569a2000-b87f-490c-92cb-11ba5ea5167c" //TX

@interface ViewController () <BLEDeviceClassDelegate>
@property (strong)		BLEBaseClass*	BaseClass;
@property (readwrite)	BLEDeviceClass*	Device;
@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //---センサー値結果のテキストフィールド生成---
    _textField=[[UITextField alloc] init];
    [_textField setFrame:CGRectMake(60,50,200,50)];  //位置と大きさ設定
    [_textField setText:@"OFFLINE"];
    [_textField setBackgroundColor:[UIColor whiteColor]];
    [_textField setBorderStyle:UITextBorderStyleRoundedRect];
    _textField.font = [UIFont fontWithName:@"Helvetica" size:30];
    [self.view addSubview:_textField];
    
    //---CONNECTボタン生成---
    _connectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_connectButton setFrame:CGRectMake(30,140,250,40)];  //位置と大きさ設定
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [_connectButton setTag:CONNECT_BUTTON];           //ボタン識別タグ
    [_connectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _connectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
    [self.view addSubview:_connectButton];
    
    //---DISCONNECTボタン生成---
    _disconnectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_disconnectButton setFrame:CGRectMake(30,210,250,40)];  //位置と大きさ設定
    [_disconnectButton setTitle:@"DIS CONNECT" forState:UIControlStateNormal];
    [_disconnectButton setTag:DISCONNECT_BUTTON];           //ボタン識別タグ
    [_disconnectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _disconnectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
    [self.view addSubview:_disconnectButton];
    
    //---FLIGHT MODEボタン生成---
    _flightModeButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_flightModeButton setFrame:CGRectMake(30,280,250,40)];  //位置と大きさ設定
    [_flightModeButton setTitle:@"FLIGHT MODE" forState:UIControlStateNormal];
    [_flightModeButton setTag:FLIGHT_MODE_BUTTON];           //ボタン識別タグ
    [_flightModeButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _flightModeButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
    [self.view addSubview:_flightModeButton];
    
    //---EMERGENCY STOPボタン生成---
    _emergencyStopButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_emergencyStopButton setFrame:CGRectMake(30,350,250,40)];  //位置と大きさ設定
    [_emergencyStopButton setTitle:@"EMERGENCY" forState:UIControlStateNormal];
    [_emergencyStopButton setTag:EMERGENCY_STOP_BUTTON];           //ボタン識別タグ
    [_emergencyStopButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _emergencyStopButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
    [self.view addSubview:_emergencyStopButton];
    
    
    //---ボタンの状態設定---
    _connectButton.enabled = TRUE;
    _disconnectButton.enabled = FALSE;
    _flightModeButton.enabled = TRUE;
    _emergencyStopButton.enabled = TRUE;
    
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
            _textField.text = [NSString stringWithFormat:@"%d", buf[0]];
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
    }else if(sender.tag==FLIGHT_MODE_BUTTON){
        [self flightModeOn];
    }else if(sender.tag==EMERGENCY_STOP_BUTTON){
        [self emergencyStop];
    }
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
        _flightModeButton.enabled = TRUE;
        _emergencyStopButton.enabled = TRUE;
        _textField.text = @"ONLINE";
        
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
        _flightModeButton.enabled = TRUE;
        _emergencyStopButton.enabled = TRUE;
		_textField.text = @"OFFLINE";
		//	周りのBLEデバイスからのadvertise情報のスキャンを開始する
		[_BaseClass scanDevices:nil];
	}
}


//フライトモード　ONコマンド
-(void)flightModeOn{
    if (_Device)	{
		//	iPhone->Device
		CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
		//	ダミーデータ
        uint8_t	buf[1];
        buf[0] = FLIGHT_MODE_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        _textField.text = (@"FLIGHT_MODE_ON");
		[_Device writeWithoutResponse:rx value:data];
	}
}

//緊急停止　コマンド
-(void)emergencyStop{
    if (_Device)	{
		//	iPhone->Device
		CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
		//	ダミーデータ
        uint8_t	buf[1];
        buf[0] = EMERGENCY_STOP_DATA;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        _textField.text = (@"EMERGENCY_STOP");
		[_Device writeWithoutResponse:rx value:data];
	}
}


@end
