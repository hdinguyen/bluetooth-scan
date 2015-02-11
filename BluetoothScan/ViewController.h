//
//  ViewController.h
//  BluetoothScan
//
//  Created by Nguyenh on 11/24/14.
//  Copyright (c) 2014 Nguyenh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMLoadingView.h"

#define SHOW_LOADING() [TMLoadingView showLoadingInView];
#define DISMISS_LOADING() [TMLoadingView dismissLoadingView];

@interface ViewController : UIViewController

@end