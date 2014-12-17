//
//  ViewController.h
//  BLESerial_test_iPhone5
//
//  Created by 石井 孝佳 on 2013/11/12.
//  Copyright (c) 2013年 浅草ギ研. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController{
    UITextField* _textField;
    UIButton* _connectButton;
    UIButton* _disconnectButton;
    
    //マルチスレッド処理　キュー
    //dispatch_queue_t loop_queue;
    
}

- (void)connect;
- (void)disconnect;
- (void)emergencyStop;

- (void)foo;
- (void)method;

@end
