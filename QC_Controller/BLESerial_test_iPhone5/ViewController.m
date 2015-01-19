//
//  ViewController.m
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//
//　ロール：ｘ軸まわりの回転、進行方向軸まわりの回転
//　ピッチ：y軸まわりの回転、上下回転
//　ヨーは、z軸まわりの回転、機体の左右回転

#import "ViewController.h"
#import "BLEBaseClass.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>

// 送信データ
#define EMPTY_DATA          0xc1                                   // 空データ
#define FLIGHT_MODE_DATA    0xd1                                   // フライトモード
#define EMERGENCY_STOP_DATA 0xe1                                   // 緊急停止
#define THROTTLE_PLUS_DATA  0x71                                   // ↑
#define THROTTLE_MINUS_DATA 0x72                                   // ↓
#define YAW_PLUS_DATA       0x81                                   // →
#define YAW_MINUS_DATA      0x82                                   // ←
#define ROLL_PLUS_DATA      0x91                                   // D
#define ROLL_MINUS_DATA     0x92                                   // A
#define CURRENT_STOP_DATA   0x93                                   // 今の位置で停まる
#define PITCH_PLUS_DATA     0x94                                   // W
#define PITCH_MINUS_DATA    0x95                                   // S

// 何秒毎に空データ送信
#define SEND_FREQUENCY      3.0f

//UUID
#define UUID_VSP_SERVICE    @"569a1101-b87f-490c-92cb-11ba5ea5167c"// VSP
#define UUID_RX             @"569a2001-b87f-490c-92cb-11ba5ea5167c"// RX
#define UUID_TX             @"569a2000-b87f-490c-92cb-11ba5ea5167c"// TX

@interface ViewController () <BLEDeviceClassDelegate>
@property (strong)		BLEBaseClass*	BaseClass;
@property (readwrite)	BLEDeviceClass*	Device;

@property BOOL connectFlag;     //接続フラグ

//ボタンステータス
@property (weak, nonatomic) IBOutlet UIButton *connectButtonStatus;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButtonStatus;

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

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //マルチスレッド起動
    [self otherThread];
    
	//AppDelegateのviewController 変数に自分(ViewController)を代入
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.viewController = self;
    
    /*
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
     */
    
    //connectフラグをFALSEにセット
    _connectFlag = FALSE;
    
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
// GoPro　ストリーミング処理
//================================================================================
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // MPMoviePlayerViewController作成
    MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:@"http://10.5.5.9:8080/live/amba.m3u8"]];
    
    MPMoviePlayerController* theMovie = [player moviePlayer];
    theMovie.scalingMode = MPMovieScalingModeAspectFit;
    theMovie.fullscreen = TRUE;
    theMovie.controlStyle = MPMovieControlStyleNone;
    theMovie.shouldAutoplay = TRUE;
    theMovie.view.frame = /*self.view.bounds;*/CGRectMake(0, 0, 1024, 768);//WVGA 800 480   //1024 768
    
    //プログラムからビューを生成
    [self.view addSubview:player.view];
    // 重なり順を最背面に
    [self.view sendSubviewToBack:player.view];
    
    player.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    
    // モーダルとして表示させる
    //[self presentMoviePlayerViewControllerAnimated:player];
    
}
-(void)logm3u8
{
    NSError *error;
    NSString *str = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://10.5.5.9:8080/live/amba.m3u8"] encoding:NSUTF8StringEncoding error:&error];
    
    NSLog(@"error:%@", error);
    NSLog(@"m3u8:\n\n%@\n\n\n", str);
}


//================================================================================
// マルチスレッド処理    空データを送り続ける
//================================================================================
-(void)otherThread {
    NSLog(@"ふううううううううううう");
    //TO-DO 操作キー押下かデータ送信時にフラグを切り替えて⇓処理実行させる　ディレイ制御
    
    // 3秒後に処理を実行
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC));

    dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
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
// 空データ送信
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
// データ送信処理
//================================================================================
- (void)sendData:(uint8_t)u_data{
    
    NSLog(@"sendData");
    if (_Device)	{
        //	iPhone->Device
        CBCharacteristic*	rx = [_Device getCharacteristic:UUID_VSP_SERVICE characteristic:UUID_RX];
        //	送信データ
        uint8_t	buf[1];
        buf[0] = u_data;
        NSData*	data = [NSData dataWithBytes:&buf length:sizeof(buf)];
        [_Device writeWithoutResponse:rx value:data];
        NSLog(@"%hhu", u_data);
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
// ボタンタップイベント   (操作キー以外)
//================================================================================

// CONNECT
- (IBAction)connectTouchUpInside:(id)sender {
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
    [self sendData:EMERGENCY_STOP_DATA];
    
}

//================================================================================
// フライトモードボタン
//================================================================================
- (IBAction)flightModeKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"FLIGHT_MODE_ON");
    [self sendData:FLIGHT_MODE_DATA];
}

//================================================================================
// 操作キー　タッチダウンイベント QuadCopter移動
//================================================================================
- (IBAction)rightKeyTouchDown:(id)sender {
    
    //_connectFlag = TRUE;
    //NSLog(@"接続したぜ");
    _textField.text = (@"YAW_PLUS");
    [self sendData:YAW_PLUS_DATA];
}

- (IBAction)leftKeyTouchDown:(id)sender {
    
    _textField.text = (@"YAW_MINUS");
    [self sendData:YAW_MINUS_DATA];
}

- (IBAction)upKeyTouchDown:(id)sender {
    
    _textField.text = (@"THROTTLE_PLUS");
    [self sendData:THROTTLE_PLUS_DATA];
}

- (IBAction)downKeyTouchDown:(id)sender {
    
    _textField.text = (@"THROTTLE_MINUS");
    [self sendData:THROTTLE_MINUS_DATA];
}

- (IBAction)wKeyTouchDown:(id)sender {

    _textField.text = (@"PITCH_PLUS");
    [self sendData:PITCH_PLUS_DATA];
}

- (IBAction)aKeyTouchDown:(id)sender {
    
    _textField.text = (@"ROLL_MINUS");
    [self sendData:ROLL_MINUS_DATA];
}

- (IBAction)sKeyTouchDown:(id)sender {
    
    _textField.text = (@"PITCH_MINUS");
    [self sendData:PITCH_MINUS_DATA];
}

- (IBAction)dKeyTouchDown:(id)sender {
    
    _textField.text = (@"ROLL_PLUS");
    [self sendData:ROLL_PLUS_DATA];
}

//================================================================================
// 操作キーを離した時の処理　　　タップ　　離した場所でQuadCopter停止処理
//================================================================================
- (IBAction)rightKeyTouchUpInside:(id)sender {

    _textField.text = (@"rightKeyTUI");
    //_connectFlag = FALSE;
    //NSLog(@"接続切ったぜ");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)leftKeyTouchUpInside:(id)sender {

    _textField.text = (@"leftKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)upKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"upKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)downKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"downKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)wKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"wKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)aKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"aKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)sKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"sKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
- (IBAction)dKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"dKeyTUI");
    [self sendData:CURRENT_STOP_DATA];
}
@end
