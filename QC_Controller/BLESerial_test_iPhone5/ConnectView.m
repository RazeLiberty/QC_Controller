//
//  ConnectView.m
//  BLESerial_test_iPhone5
//
//  Created by Raze-Mac on 2014/11/12.
//  Copyright (c) 2014年 石井 孝佳. All rights reserved.
//

#import "ConnectView.h"
#import "BLEBaseClass.h"
#import <CoreBluetooth/CoreBluetooth.h>

//ボタンタグ
#define CONNECT_BUTTON 0
#define DISCONNECT_BUTTON 1
/*
 #define FLIGHT_MODE_BUTTON 2
 #define EMERGENCY_STOP_BUTTON 3
 #define DEFAULT_BUTTON 4
 #define THROTTLE_BUTTON 5
 #define THROTTLE_PLUS_BUTTON 6
 #define THROTTLE_MINUS_BUTTON 7
 #define ROLL_BUTTON 8
 #define PITCH_BUTTON 9
 #define YAW_BUTTON 10
 #define YAW_PLUS_BUTTON 11
 #define YAW_MINUS_BUTTON 12
 */

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

@interface ConnectView () <BLEDeviceClassDelegate>
@property (strong)		BLEBaseClass*	BaseClass;
@property (readwrite)	BLEDeviceClass*	Device;


@end

@implementation ConnectView


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
    //	ストーリーボード使わないなら　/**/
    //------------------------------------------------------------------------------------------
    
    //---CONNECTボタン生成---
    _connectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_connectButton setFrame:CGRectMake(BUTTON_LOCATE_X,120,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [_connectButton setTag:CONNECT_BUTTON];           //ボタン識別タグ
    
    [_connectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _connectButton.center = self.view.center;
    _connectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_connectButton];
    /*
    //---DISCONNECTボタン生成---
    _disconnectButton=[UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_disconnectButton setFrame:CGRectMake(BUTTON_LOCATE_X,150,BUTTON_SIZE_X,BUTTON_SIZE_Y)];  //位置と大きさ設定
    [_disconnectButton setTitle:@"DIS CONNECT" forState:UIControlStateNormal];
    [_disconnectButton setTag:DISCONNECT_BUTTON];           //ボタン識別タグ
    [_disconnectButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];             //ボタンクリックイベント登録
    _disconnectButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:TEXT_SIZE];
    [self.view addSubview:_disconnectButton];
    //---ボタンの状態設定---
    _connectButton.enabled = TRUE;
    _disconnectButton.enabled = FALSE;
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
    }/*else if(sender.tag==DISCONNECT_BUTTON){
        [self disconnect];
    }*/
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
       //  _disconnectButton.enabled = TRUE;

        //	tx(Device->iPhone)のnotifyをセット
        CBCharacteristic*	tx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_TX];
        if (tx)	{
            //            [_Device readRequest:tx];
            [_Device notifyRequest:tx];
        }
        ControllView *ControllView = [self.storyboard instantiateViewControllerWithIdentifier:@"ControllView"];
        [self presentViewController:ControllView animated:YES completion:nil];
    }
}
/*
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
        
        _textField.text = @"OFFLINE";
        
        //	周りのBLEデバイスからのadvertise情報のスキャンを開始する
        [_BaseClass scanDevices:nil];
    }
}
 */

//前画面に戻る
- (IBAction)goBack:(UIStoryboardSegue *)sender{}
@end

