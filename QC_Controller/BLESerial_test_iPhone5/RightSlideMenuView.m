//
//  RightSlideMenuView.m
//  BLESerial_test_iPhone5
//
//  Created by Takehiro Kawahawa on 2015/01/28.
//  Copyright (c) 2015年 石井 孝佳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RightSlideMenuView.h"

@implementation RightSlideMenuView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.frame = CGRectMake( [UIScreen mainScreen].bounds.size.width, 0, 160, 568);
        self.backgroundColor = [UIColor yellowColor];
        UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(30, 100, 100, 100)];
        title.text = @"スライドメニューが表示されました";
        title.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end