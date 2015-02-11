//
//  TMLoadingView.m
//  TNCS
//
//  Created by Nguyenh on 8/18/14.
//  Copyright (c) 2014 TEDMate. All rights reserved.
//

#import "TMLoadingView.h"
#import "AppDelegate.h"

@implementation TMLoadingView

static TMLoadingView* loadingView = nil;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _blurView = [[UIView alloc]initWithFrame:frame];
        [_blurView setBackgroundColor:[UIColor blackColor]];
        [_blurView setAlpha:0.2f];
        [self addSubview:_blurView];
        
        _indicatorView  = [[MONActivityIndicatorView alloc] init];
        _indicatorView.delegate = self;
        _indicatorView.numberOfCircles = 5;
        _indicatorView.radius = 8;
        _indicatorView.internalSpacing = 8;
        _indicatorView.center = self.center;
        [_indicatorView startAnimating];
        [self addSubview:_indicatorView];
    }
    return self;
}

- (UIColor *)activityIndicatorView:(MONActivityIndicatorView *)activityIndicatorView
      circleBackgroundColorAtIndex:(NSUInteger)index {
    CGFloat red   = (arc4random() % 256)/255.0;
    CGFloat green = (arc4random() % 256)/255.0;
    CGFloat blue  = (arc4random() % 256)/255.0;
    CGFloat alpha = 1.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+(void)showLoadingInView
{
    AppDelegate* appDelegate = (((AppDelegate*) [UIApplication sharedApplication].delegate));
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadingView = [[TMLoadingView alloc] initWithFrame:appDelegate.window.frame];
        [loadingView setBackgroundColor:[UIColor clearColor]];
    });
    [loadingView.indicatorView startAnimating];
    [appDelegate.window addSubview:loadingView];
}

+(void)dismissLoadingView
{
    [loadingView.indicatorView stopAnimating];
    [loadingView removeFromSuperview];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
