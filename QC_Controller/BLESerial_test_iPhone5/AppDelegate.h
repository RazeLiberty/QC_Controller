//
//  AppDelegate.h
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//


#import <UIKit/UIKit.h>

@class ViewController;  //ViewController はクラス名。それ以上のことは気にせずコンパイル
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain, nonatomic) ViewController *viewController;
@end
