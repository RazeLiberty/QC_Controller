//
//  ViewController.h
//  QC_Controller
//
//  Created by Takehiro Kawahara on 2014/11/4.
//  Copyright (c) 2014年 Takehiro Kawahara. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController{

    UITextField* _textField;

}

- (void)connect;
- (void)disconnect;
- (void)emergencyStop;

- (void)otherThread;
- (void)loopBackground;

@end
