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


// 送信データ
#define EMPTY_DATA          0xc1                                   // 空データ
#define FLIGHT_MODE_DATA    0xd1                                   // フライトモード
#define EMERGENCY_STOP_DATA 0xe1                                   // 緊急停止
#define THROTTLE_PLUS_DATA  0x71                                   // ↑
#define THROTTLE_MINUS_DATA 0x72                                   // ↓
#define THROTTLE_CURRENT_DATA 0x73                                   // 今の位置で止まる
#define YAW_PLUS_DATA       0x81                                   // →
#define YAW_MINUS_DATA      0x82                                   // ←
#define YAW_CURRENT_DATA    0x83                                   // 今の位置で止まる
#define ROLL_PLUS_DATA      0x91                                   // D
#define ROLL_MINUS_DATA     0x92                                   // A
#define YAW_PITCH_CURRENT_STOP_DATA   0x93                                   // 今の位置で停まる
#define PITCH_PLUS_DATA     0x94                                   // W
#define PITCH_MINUS_DATA    0x95                                   // S

// メニュー　→　設定
#define YAW_HOME_ERROR_P_1_CODE 0xa1
#define YAW_HOME_ERROR_P_3_CODE 0xa2
#define YAW_HOME_ERROR_P_5_CODE 0xa3
#define YAW_HOME_ERROR_P_10_CODE 0xa4
#define YAW_HOME_ERROR_0_CODE 0xa5
#define YAW_HOME_ERROR_M_1_CODE 0xa6
#define YAW_HOME_ERROR_M_3_CODE 0xa7
#define YAW_HOME_ERROR_M_5_CODE 0xa8
#define YAW_HOME_ERROR_M_10_CODE 0xa9
#define THROTTLE_HOME_ERROR_P_1_CODE 0xb1
#define THROTTLE_HOME_ERROR_P_3_CODE 0xb2
#define THROTTLE_HOME_ERROR_P_5_CODE 0xb3
#define THROTTLE_HOME_ERROR_P_10_CODE 0xb4
#define THROTTLE_HOME_ERROR_NO_COVER_CODE 0xb5
#define THROTTLE_HOME_ERROR_M_1_CODE 0xb6
#define THROTTLE_HOME_ERROR_M_3_CODE 0xb7
#define THROTTLE_HOME_ERROR_M_5_CODE 0xb8
#define THROTTLE_HOME_ERROR_M_10_CODE 0xb9
#define THROTTLE_HOME_ERROR_COVER_CODE 0xba

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

- (IBAction)cameraOn:(id)sender;
- (IBAction)cameraOff:(id)sender;

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
// メニュー実装
//================================================================================
// 「選択」ボタンがタップされたときに呼び出されるメソッド
- (IBAction)openTableView:(id)sender {
    // PickerViewControllerのインスタンスをStoryboardから取得し
    self.tableViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"TableViewController"];
    self.tableViewController.delegate = self;
    
    // PickerViewをサブビューとして表示する
    // 表示するときはアニメーションをつけて下から上にゆっくり表示させる
    
    // アニメーション完了時のPickerViewの位置を計算
    UIView *tableView = self.tableViewController.view;
    CGPoint middleCenter = tableView.center;
    
    // アニメーション開始時のPickerViewの位置を計算
    UIWindow* mainWindow = (((AppDelegate*) [UIApplication sharedApplication].delegate).window);
    CGSize offSize = [UIScreen mainScreen].bounds.size;
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height * 1.5);
    tableView.center = offScreenCenter;
    
    [mainWindow addSubview:tableView];
    
    // アニメーションを使ってPickerViewをアニメーション完了時の位置に表示されるようにする
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    tableView.center = middleCenter;
    [UIView commitAnimations];
}
/*
 // PickerViewのある行が選択されたときに呼び出されるPickerViewControllerDelegateプロトコルのデリゲートメソッド
 - (void)applySelectedString:(NSString *)str
 {
 self.selectedStringLabel.text = str;
 }
 */
// PickerViewController上にある透明ボタンがタップされたときに呼び出されるPickerViewControllerDelegateプロトコルのデリゲートメソッド
- (void)closeTableView:(TableViewController *)controller
{
    // PickerViewをアニメーションを使ってゆっくり非表示にする
    UIView *tableView = controller.view;
    
    // アニメーション完了時のPickerViewの位置を計算
    CGSize offSize = [UIScreen mainScreen].bounds.size;
    CGPoint offScreenCenter = CGPointMake(offSize.width / 2.0, offSize.height * 1.5);
    
    [UIView beginAnimations:nil context:(void *)tableView];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    // アニメーション終了時に呼び出す処理を設定
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    tableView.center = offScreenCenter;
    [UIView commitAnimations];
}

// 単位のPickerViewを閉じるアニメーションが終了したときに呼び出されるメソッド
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    // PickerViewをサブビューから削除
    UIView *tableView = (__bridge UIView *)context;
    [tableView removeFromSuperview];
}


//================================================================================
// GoPro　ストリーミング処理
//================================================================================
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //AppDelegateのviewController 変数に自分(ViewController)を代入
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.playerView = self;
    
    // MPMoviePlayerViewController作成
    MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:@"http://10.5.5.9:8080/live/amba.m3u8"]];
    
    theMovie = [player moviePlayer];
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
    
    //再生準備
    //    [theMovie prepareToPlay];
    
    // モーダルとして表示させる
    //[self presentMoviePlayerViewControllerAnimated:player];
    
}
-(void)play
{
    [theMovie play];
    //cameraFlag = TRUE;
}
- (void)stop
{
    [theMovie stop];
    //cameraFlag = FALSE;
}
- (IBAction)cameraOn:(id)sender {
    [self play];
}
- (IBAction)cameraOff:(id)sender {
    [self stop];
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
    NSLog(@"FLIGHT_MODE_DATA");
}

//================================================================================
// フライトモードボタン
//================================================================================
- (IBAction)flightModeKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"FLIGHT_MODE_ON");
    [self sendData:FLIGHT_MODE_DATA];
    NSLog(@"FLIGHT_MODE_DATA");
}

//================================================================================
// 操作キー　タッチダウンイベント QuadCopter移動
//================================================================================
- (IBAction)rightKeyTouchDown:(id)sender {
    
    //_connectFlag = TRUE;
    //NSLog(@"接続したぜ");
    _textField.text = (@"YAW_PLUS");
    [self sendData:YAW_PLUS_DATA];
    NSLog(@"YAW_PLUS");
}

- (IBAction)leftKeyTouchDown:(id)sender {
    
    _textField.text = (@"YAW_MINUS");
    [self sendData:YAW_MINUS_DATA];
    NSLog(@"YAW_MINUS");
}

- (IBAction)upKeyTouchDown:(id)sender {
    
    _textField.text = (@"THROTTLE_PLUS");
    [self sendData:THROTTLE_PLUS_DATA];
    NSLog(@"THROTTLE_PLUS");
}

- (IBAction)downKeyTouchDown:(id)sender {
    
    _textField.text = (@"THROTTLE_MINUS");
    [self sendData:THROTTLE_MINUS_DATA];
    NSLog(@"THROTTLE_MINUS");
}

- (IBAction)wKeyTouchDown:(id)sender {
    
    _textField.text = (@"PITCH_PLUS");
    [self sendData:PITCH_PLUS_DATA];
    NSLog(@"PITCH_PLUS");
}

- (IBAction)aKeyTouchDown:(id)sender {
    
    _textField.text = (@"ROLL_MINUS");
    [self sendData:ROLL_MINUS_DATA];
    NSLog(@"ROLL_MINUS");
}

- (IBAction)sKeyTouchDown:(id)sender {
    
    _textField.text = (@"PITCH_MINUS");
    [self sendData:PITCH_MINUS_DATA];
    NSLog(@"PITCH_MINUS");
}

- (IBAction)dKeyTouchDown:(id)sender {
    
    _textField.text = (@"ROLL_PLUS");
    [self sendData:ROLL_PLUS_DATA];
    NSLog(@"ROLL_PLUS");
}

//================================================================================
// 操作キーを離した時の処理　　　タップ　　離した場所でQuadCopter停止処理
//================================================================================
- (IBAction)rightKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"rightKeyTUI");
    //_connectFlag = FALSE;
    //NSLog(@"接続切ったぜ");
    [self sendData:YAW_CURRENT_DATA];
    NSLog(@"YAW_CURRENT_DATA");
}
- (IBAction)leftKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"leftKeyTUI");
    [self sendData:YAW_CURRENT_DATA];
    NSLog(@"YAW_CURRENT_DATA");
}
- (IBAction)upKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"upKeyTUI");
    [self sendData:THROTTLE_CURRENT_DATA];
    NSLog(@"THROTTLE_CURRENT_DATA");
}
- (IBAction)downKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"downKeyTUI");
    [self sendData:THROTTLE_CURRENT_DATA];
    NSLog(@"THROTTLE_CURRENT_DATA");
}
- (IBAction)wKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"wKeyTUI");
    [self sendData:YAW_PITCH_CURRENT_STOP_DATA];
    NSLog(@"YAW_PITCH_CURRENT_STOP_DATA");
}
- (IBAction)aKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"aKeyTUI");
    [self sendData:YAW_PITCH_CURRENT_STOP_DATA];
    NSLog(@"YAW_PITCH_CURRENT_STOP_DATA");
}
- (IBAction)sKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"sKeyTUI");
    [self sendData:YAW_PITCH_CURRENT_STOP_DATA];
    NSLog(@"YAW_PITCH_CURRENT_STOP_DATA");
}
- (IBAction)dKeyTouchUpInside:(id)sender {
    
    _textField.text = (@"dKeyTUI");
    [self sendData:YAW_PITCH_CURRENT_STOP_DATA];
    NSLog(@"YAW_PITCH_CURRENT_STOP_DATA");
}

@end


//================================================================================
// メニュー　テーブルビュー実装
//================================================================================

@interface TableViewController ()


// テーブルに表示する情報が入る
@property (nonatomic, strong) NSArray *dataSourceMenu;
//@property (nonatomic, strong) NSArray *dataSourceYaw;

@end

@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TableViewのデリゲート先とデータソースをこのクラスに設定
    self.table.delegate = self;
    self.table.dataSource = self;
    //self.table.allowsSelection = YES;   //行選択の可否
    
    // テーブルに表示したいデータソースをセット
    self.dataSourceMenu = @[@"iPhone 4"];
    //self.dataSourceYaw = @[@"Nexus", @"Galaxy", @"Xperia"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//セクション数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


// テーブルにいくつのデータがあるか
/**
 テーブルに表示するデータ件数を返す（必須）
 
 @return NSInteger : データ件数
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


// テーブルの中のセルはどんなセルか
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault                            reuseIdentifier:CellIdentifier];
    }
    
    // ボタンを作成して、tableViewCellに載せます。
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    // rectのx,yは、0で良い。accessoryViewで自動的に上下中央にしてくれる。
    button.frame = CGRectMake(0, 0, 200, 0);
    // ボタンのラベルを指定するには、以下のメソッド。titleプロパティに代入しても反映されない。
    [button setTitle:@"Bluetooth強制解除" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(tapButton:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = button;
    
    cell.textLabel.text = @"";
    
    return cell;
}

// ボタンがタップされた際に呼び出されるメソッド
-(void)tapButton:(id)sender {
    NSLog(@"Execute Button tapped.");
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Setting" sender:self];
}

// 空の領域にある透明なボタンがタップされたときに呼び出されるメソッド
- (IBAction)closeTableView:(id)sender {
    // TableViewを閉じるための処理を呼び出す
    [self.delegate closeTableView:self];
}

@end