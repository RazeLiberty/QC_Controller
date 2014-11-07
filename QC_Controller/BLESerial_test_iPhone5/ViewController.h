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
    UIButton* _flightModeButton;
    UIButton* _emergencyStopButton;
    UIButton* _defaultButton;
    UIButton* _throttleButton;
    UIButton* _throttlePlusButton;
    UIButton* _throttleMinusButton;
    UIButton* _rollButton;
    UIButton* _pitchButton;
    UIButton* _yawButton;
    UIButton* _yawPlusButton;
    UIButton* _yawMinusButton;
}

@end
