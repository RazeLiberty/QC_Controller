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
// メニュー
//================================================================================
@protocol TableViewControllerDelegate;

@interface TableViewController : UIViewController <UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *table;

// 空の領域にある透明なボタン
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

// 処理のデリゲート先の参照
@property (weak, nonatomic) id<TableViewControllerDelegate> delegate;

// PickerViewを閉じる処理を行うメソッド。closeButtonが押下されたときに呼び出される
- (IBAction)closeTableView:(id)sender;

@end


@protocol TableViewControllerDelegate <NSObject>
// 選択された文字列を適用するためのデリゲートメソッド
//-(void)applySelectedString:(NSString *)str;
// 当該MenuViewを閉じるためのデリゲートメソッド
-(void)closeTableView:(TableViewController *)controller;
@end

//================================================================================
// 操作画面
//================================================================================
@interface ViewController : UIViewController <TableViewControllerDelegate> {
    
    UITextField* _textField;
    MPMoviePlayerController* theMovie;
    //Boolean* cameraFlag;     //カメラ接続フラグ
    
}
- (void)connect;
- (void)disconnect;
- (void)emergencyStop;

- (void)otherThread;
- (void)loopBackground;

- (void)play;
- (void)stop;

// 「選択」ボタン
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
/*// TableViewで選択された文字列を表示するラベル
 @property (weak, nonatomic) IBOutlet UILabel *selectedStringLabel;
 */
// 呼び出すTableViewControllerのポインタ　※strongを指定してポインタを掴んでおかないと解放されてしまう
@property (strong, nonatomic) TableViewController *tableViewController;

// 「選択」ボタンがタップされたときに呼び出されるメソッド
- (IBAction)openTableView:(id)sender;

@end

