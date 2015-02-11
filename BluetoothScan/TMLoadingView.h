//
//  TMLoadingView.h
//  TNCS
//
//  Created by Nguyenh on 8/18/14.
//  Copyright (c) 2014 TEDMate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MONActivityIndicatorView.h"

@interface TMLoadingView : UIView <MONActivityIndicatorViewDelegate>
{
    UIView* _blurView;
}

@property (nonatomic, retain) MONActivityIndicatorView *indicatorView;

+(void)showLoadingInView;
+(void)dismissLoadingView;

@end
