//
//  AppDelegate.h
//  BLESerial_test_iPhone5
//
//  Created by 石井 孝佳 on 2013/11/12.
//  Copyright (c) 2013年 石井 孝佳. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;  //ViewController はクラス名。それ以上のことは気にせずコンパイル
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain, nonatomic) ViewController *viewController;
@end
