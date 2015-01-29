//
//  ViewController.h
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController{

    UITextField* _textField;
    MPMoviePlayerController* theMovie;
    //Boolean* cameraFlag;     //カメラ接続フラグ
}

//Bluetooth通信
- (void)connect;
- (void)disconnect;
- (void)emergencyStop;

//マルチスレッド
- (void)otherThread;
- (void)loopBackground;

//カメラストリーミング
- (void)play;
- (void)stop;

- (void)inputMenuview;  //メニュービュー

@end
