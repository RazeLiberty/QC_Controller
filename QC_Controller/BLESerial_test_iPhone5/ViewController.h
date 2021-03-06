//
//  ViewController.h
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>



//================================================================================
// 操作画面
//================================================================================
@interface ViewController : UIViewController {
    
    UITextField* _textField;
    MPMoviePlayerController* theMovie;
    //Boolean* cameraFlag;     //カメラ接続フラグ
    
}
- (void)connect;
- (void)disconnect;
- (void)emergencyStop;

- (void)otherThread;
- (void)loopBackground;

- (void)menuBluetoothDefuse;

- (void)play;
- (void)stop;

// 「選択」ボタン
@property (weak, nonatomic) IBOutlet UIButton *selectButton;

@end

