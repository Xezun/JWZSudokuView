//
//  JWZSudokuView.h
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

// 田字格、九宫格视图

#import <UIKit/UIKit.h>

@protocol JWZSudokuViewDelegate, JWZSudokuViewModelRTF;

@interface JWZSudokuView : UIView

// 非 autoLayout 布局时，可以使用此方法获取高度
+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)width separator:(CGFloat)separator;
+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)width separator:(CGFloat)separator aspectRatio:(CGFloat)aspectRatio;

// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame aspectRatio:(CGFloat)aspectRatio;

// aspectRatio 是 宽/高 的值，默认 1.0。
@property (nonatomic, readonly) CGFloat aspectRatio;

// 图片间的间隔，默认 1.0 。
@property (nonatomic) CGFloat separator;

// 事件代理
@property (nonatomic, weak) id<JWZSudokuViewDelegate> delegate;

// 返回正在显示的图片
- (NSArray<UIImageView *> *)allImageViews;

// 加载网络图片
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls;
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)image;

// 直接加载图片
- (void)setContentWithImages:(NSArray<UIImage *> *)images;

// 通过 model 加载图片
// 如果图片 URL 是一个 model 的属性，该 model 遵循 JWZSudokuViewModelRTF 协议，可以使用下面的方法
- (void)setContentWithModels:(NSArray<id<JWZSudokuViewModelRTF>> *)models placeholder:(UIImage *)image;

@end


@protocol JWZSudokuViewDelegate <NSObject>

@optional
- (void)sudokuView:(JWZSudokuView *)sudokuView didTouchOnImageView:(UIImageView *)imageView atIndex:(NSInteger)index;

@end
