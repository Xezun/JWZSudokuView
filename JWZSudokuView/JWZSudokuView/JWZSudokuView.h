//
//  JWZSudokuView.h
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

// 田字格、九宫格视图

#import <UIKit/UIKit.h>

@protocol JWZSudokuViewDelegate, JWZSudokuViewOptimizer;

@interface JWZSudokuView : UIView

// 默认间距
+ (CGFloat)defaultSeparator;

// 默认宽高比
+ (CGFloat)defaultAspectRatio;

// 默认间距下，每个小图的宽度
+ (CGFloat)itemWidthWithTotalWidth:(CGFloat)totalWidth itemCount:(NSUInteger)count;

// 计算每个小图的宽度
+ (CGFloat)itemWidthWithTotalWidth:(CGFloat)totalWidth itemCount:(NSUInteger)count separator:(CGFloat)separator;

// 默认间距下，默认宽高比，整个视图的高度
+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth;

// 指定间距下，默认宽高比，整个视图的高度
+ (CGFloat)heightForItemCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator;

// 计算视图的高度
+ (CGFloat)heightForItemCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator aspectRatio:(CGFloat)aspectRatio;

// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame aspectRatio:(CGFloat)aspectRatio;

// aspectRatio 是 宽/高 的值，默认 1.0。
@property (nonatomic, readonly) CGFloat aspectRatio;

// 图片间的间隔，默认 3.0 。
@property (nonatomic) CGFloat separator;

// 单张图片的优化设置
@property (nonatomic, weak, readonly) id<JWZSudokuViewOptimizer> optimizer; // 该代理方法返回 图片的实际高度
@property (nonatomic) CGFloat maxScaleForSingleImage;  // 单张图片优化时，单张图片的最大宽度与视图最大宽度的比值，默认 0.8。
@property (nonatomic) CGFloat minScaleForSingleImage;  // 最小比值，默认 0.4

@property (nonatomic, readonly) BOOL optimizeForSingleImage;

// 事件代理
@property (nonatomic, weak) id<JWZSudokuViewDelegate> delegate;

// 返回正在显示的图片
- (NSArray<UIImageView *> *)allImageViews;

// 直接加载图片
- (void)setContentWithImages:(NSArray<UIImage *> *)images;
- (void)setContentWithImages:(NSArray<UIImage *> *)images optimizeForSingleImage:(BOOL)optimize;

// 加载网络图片
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls;
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)placeholder;
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)placeholder optimizer:(id<JWZSudokuViewOptimizer>)optimizer;

@end

@protocol JWZSudokuViewOptimizer <NSObject>

@required
- (CGFloat)sudokuView:(JWZSudokuView *)sudokuView heightForSingleImageView:(UIImageView *)imageView;
- (CGFloat)sudokuView:(JWZSudokuView *)sudokuView widthForSingleImageView:(UIImageView *)imageView;

@end

@protocol JWZSudokuViewDelegate <NSObject>

@optional
- (void)sudokuView:(JWZSudokuView *)sudokuView didTouchOnImageView:(UIImageView *)imageView atIndex:(NSInteger)index;

@end
