//
//  JWZSudokuView.m
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import "JWZSudokuView.h"
#import <objc/runtime.h>
#import "UIImageView+WebCache.h"

static inline CGFloat JWZAspectRatio(CGFloat width, CGFloat height) {
    return (height == 0 ? height : width / height);
}

static void const *const kJWZSudokuViewWidthConstraintToken   = &kJWZSudokuViewWidthConstraintToken;// 宽度
static void const *const kJWZSudokuViewHeightConstraintToken  = &kJWZSudokuViewHeightConstraintToken;// 高度
static void const *const kJWZSudokuViewLeadingConstraintToken = &kJWZSudokuViewLeadingConstraintToken;// item 距左边
static void const *const kJWZSudokuViewTopConstraintToken     = &kJWZSudokuViewTopConstraintToken;// item 距右边

@interface JWZSudokuWrapperView : UIView

@end

@interface JWZSudokuView ()

@property (nonatomic, strong) JWZSudokuWrapperView *wrapperView;// 容器视图
@property (nonatomic, weak  ) NSLayoutConstraint   *wrapperHeightConstraint;// 容器视图的高度约束
@property (nonatomic, strong) NSMutableArray<UIImageView *> *contentViews;// 正在显示的图片
@property (nonatomic, strong) NSMutableArray<UIImageView *> *reusableContentViews;// 重用池

@end

@implementation JWZSudokuView

#pragma mark - 类方法

// 默认间距
+ (CGFloat)defaultSeparator {
    return 3.0;
}

// 默认宽高比
+ (CGFloat)defaultAspectRatio {
    return 1.0;
}

// 默认间距下，每个小图的宽度
+ (CGFloat)itemWidthWithTotalWidth:(CGFloat)totalWidth itemCount:(NSUInteger)count {
    return [self itemWidthWithTotalWidth:totalWidth itemCount:(NSUInteger)count separator:[self defaultSeparator]];
}

// 计算每个小图的宽度
+ (CGFloat)itemWidthWithTotalWidth:(CGFloat)totalWidth itemCount:(NSUInteger)count separator:(CGFloat)separator {
    return (totalWidth - separator * 2) / 3.0;
}

// 默认间距下，默认宽高比，整个视图的高度
+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth {
    return [self heightForItemCount:count totalWidth:totalWidth separator:[self defaultSeparator]];
}

// 指定间距下，默认宽高比，整个视图的高度
+ (CGFloat)heightForItemCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator {
    return [self heightForItemCount:count totalWidth:totalWidth separator:separator aspectRatio:[self defaultAspectRatio]];
}

// 计算视图的高度
+ (CGFloat)heightForItemCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator aspectRatio:(CGFloat)aspectRatio {
    NSInteger totalRow = ceil(MIN(9, count) / 3.0); // 进位取整，总行数
    CGFloat itemWidth = [self itemWidthWithTotalWidth:totalWidth itemCount:count separator:separator];
    return (totalRow * (itemWidth / aspectRatio + separator) - separator);
}

#pragma mark - 初始化方法

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame aspectRatio:[[self class] defaultAspectRatio]];
}

- (instancetype)initWithFrame:(CGRect)frame aspectRatio:(CGFloat)aspectRatio {
    self = [super initWithFrame:frame];
    if (self != nil) {
        _aspectRatio = aspectRatio;
    }
    return self;
}

#pragma mark - 存档的支持

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        _aspectRatio = [[aDecoder decodeObjectForKey:@"aspectRatio"] doubleValue];
        if (_aspectRatio <= 0) {
            _aspectRatio = [[self class] defaultAspectRatio];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[NSNumber numberWithDouble:_aspectRatio] forKey:@"aspectRatio"];
}

#pragma mark - 属性

- (CGFloat)separator {
    if (_separator > 0) {
        return _separator;
    }
    _separator = [[self class] defaultSeparator];
    return _separator;
}

- (JWZSudokuWrapperView *)wrapperView {
    if (_wrapperView != nil) {
        return _wrapperView;
    }
    _wrapperView = [[JWZSudokuWrapperView alloc] init];
    [self addSubview:_wrapperView];
    _wrapperView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 水平与父视图相等
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_wrapperView]|" options:(NSLayoutFormatAlignAllLeft) metrics:nil views:NSDictionaryOfVariableBindings(_wrapperView)];
    [self addConstraints:constraints];
    
    // 顶部与父视图相等
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem:_wrapperView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeTop) multiplier:1.0 constant:0];
    [self addConstraint:constraint1];
    
    // 高度与父视图相等
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint constraintWithItem:_wrapperView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:self attribute:(NSLayoutAttributeHeight) multiplier:1.0 constant:0];
    constraint2.priority = 500;
    [self addConstraint:constraint2];
    
    // 高度的约束，默认 0
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:_wrapperView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:height];
    _wrapperHeightConstraint = height;
    
    return _wrapperView;
}

- (NSMutableArray<UIImageView *> *)contentViews {
    if (_contentViews != nil) {
        return _contentViews;
    }
    _contentViews = [NSMutableArray array];
    return _contentViews;
}

- (NSMutableArray<UIImageView *> *)reusableContentViews {
    if (_reusableContentViews != nil) {
        return _reusableContentViews;
    }
    _reusableContentViews = [NSMutableArray array];
    return _reusableContentViews;
}

- (CGFloat)maxScaleForSingleImage {
    if (_maxScaleForSingleImage > 0 && _maxScaleForSingleImage <= 1.0) {
        return _maxScaleForSingleImage;
    }
    _maxScaleForSingleImage = 0.80;
    return _maxScaleForSingleImage;
}

- (CGFloat)minScaleForSingleImage {
    if (_minScaleForSingleImage > 0 && _minScaleForSingleImage <= 1.0) {
        return _minScaleForSingleImage;
    }
    _minScaleForSingleImage = 0.40;
    return _minScaleForSingleImage;
}

- (void)setOptimizer:(id<JWZSudokuViewOptimizer>)optimizer {
    if (_optimizer != optimizer) {
        _optimizer = optimizer;
        [self setNeedsLayout];
    }
}

- (void)setAspectRatio:(CGFloat)aspectRatio {
    if (aspectRatio != _aspectRatio && aspectRatio > 0) {
        _aspectRatio = aspectRatio;
        [self setNeedsLayout];
    }
}

#pragma mark - 方法

// 从重用池取一个 ImageView
- (UIImageView *)dequeueReusableContentView {
    UIImageView *imageView = [self.reusableContentViews lastObject];
    if (imageView != nil) {
        imageView.hidden = NO;
        [_reusableContentViews removeObject:imageView];
    } else {
        imageView = [self createAnImageView];
    }
    return imageView;
}

// 把 ImageView 加入重用池
- (void)queueReusableContentView:(UIImageView *)imageView {
    imageView.hidden = YES;
    imageView.image = nil;
    [self.reusableContentViews addObject:imageView];
}

// 创建一个 ImageView
- (UIImageView *)createAnImageView {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.borderColor = [UIColor colorWithWhite:0.97 alpha:1].CGColor;
    imageView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    [self.wrapperView addSubview:imageView];
    
    imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [imageView addGestureRecognizer:tap];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    // 距父视图的上边
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeTop) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:top];
    objc_setAssociatedObject(imageView, kJWZSudokuViewTopConstraintToken, top, OBJC_ASSOCIATION_ASSIGN);

    // 距父视图的左边
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeLeading) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeLeading) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:leading];
    objc_setAssociatedObject(imageView, kJWZSudokuViewLeadingConstraintToken, leading, OBJC_ASSOCIATION_ASSIGN);
    
    // 高度约束
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
    [imageView addConstraint:height];
    objc_setAssociatedObject(imageView, kJWZSudokuViewHeightConstraintToken, height, OBJC_ASSOCIATION_ASSIGN);
    
    // 宽
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
    [imageView addConstraint:width];
    objc_setAssociatedObject(imageView, kJWZSudokuViewWidthConstraintToken, width, OBJC_ASSOCIATION_ASSIGN);
    return imageView;
}

// 创建需要显示的内容
- (void)setContentWithCount:(NSInteger)newContentCount {
    newContentCount = MIN(9, newContentCount);
    NSInteger oldContentCount = self.contentViews.count;
    if (oldContentCount < newContentCount) {
        for (NSInteger i = oldContentCount; i < newContentCount; i ++) {
            [_contentViews addObject:[self dequeueReusableContentView]];
        }
    } else if (oldContentCount > newContentCount) {
        for (NSInteger i = oldContentCount - 1; i >= newContentCount; i --) {
            UIImageView *imageView = _contentViews[i];
            [_contentViews removeObjectAtIndex:i];
            [self queueReusableContentView:imageView];  // 回收 Image View
        }
    }
}

// 添加图片
- (void)setContentWithImages:(NSArray<UIImage *> *)images {
    NSInteger count = images.count;
    [self setContentWithCount:count];
    if (count > 0) {
        [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.image = [images objectAtIndex:idx];
        }];
    }
    [self setNeedsLayout];
}

// 添加网络图片
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls {
    [self setContentWithImageUrls:urls placeholder:nil];
}

// 添加网络图片，在图片下载前使用占位图
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)placeholder {
    NSInteger count = urls.count;
    [self setContentWithCount:count];
    if (count > 0) {
        [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL *url = [NSURL URLWithString:[urls objectAtIndex:idx]];
            [obj sd_setImageWithURL:url placeholderImage:placeholder];
        }];
    }
    [self setNeedsLayout];
}

#pragma mark - 布局图片

- (void)layoutImageViews {
    NSInteger itemCount = _contentViews.count;
    CGFloat totalWidth  = self.bounds.size.width;
    
    CGFloat totalHeight = 0; // 总高度
    CGFloat itemWidth   = 0; // 每个小图的宽度
    CGFloat itemHeight  = 0; // 小图的高度
    NSInteger rowSize   = 0; // 每行小图的个数

    
    if (itemCount > 1 || self.optimizer == nil) {
        totalHeight = [[self class] heightForItemCount:itemCount totalWidth:totalWidth separator:self.separator aspectRatio:self.aspectRatio];
        itemWidth   = [[self class] itemWidthWithTotalWidth:totalWidth itemCount:itemCount separator:_separator];
        itemHeight  = itemWidth / _aspectRatio;
        rowSize     = [self rowSizeForItemCount:itemCount];
    } else if (itemCount == 1 && self.optimizer != nil) {
        UIImageView *imageView = [[self contentViews] firstObject];
        // 图片原始大小，通过代理方法获取
        CGFloat oWidth  = [self.optimizer sudokuView:self widthForSingleImageView:imageView];
        CGFloat oHeight = [self.optimizer sudokuView:self heightForSingleImageView:imageView];
        // 图片原始宽高比
        CGFloat aspectRatio   = JWZAspectRatio(oWidth, oHeight);
        // 宽高比最大值和最小值
        CGFloat maxAspect = self.maxScaleForSingleImage / self.minScaleForSingleImage;
        CGFloat minAspect = 1.0 / maxAspect;
        if (aspectRatio > maxAspect) {
            aspectRatio = maxAspect;
        } else if (aspectRatio < minAspect) {
            aspectRatio = minAspect;
        }
        CGFloat maxWidth   = totalWidth * self.maxScaleForSingleImage;
        CGFloat maxHeight  = maxWidth;
        if (aspectRatio > 1) {
            itemWidth = maxWidth;
            itemHeight = maxWidth / aspectRatio;
        } else {
            itemWidth = maxHeight * aspectRatio;
            itemHeight = maxHeight;
        }
        rowSize = 1;
        totalHeight = itemHeight;
    }
    
    self.wrapperHeightConstraint.constant = totalHeight;
    
    [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger row = idx / rowSize;
        NSInteger col = idx % rowSize;
        [self setImageView:obj index:idx constraintsWithTop:(row * (itemHeight  + _separator)) leading:(col * (itemWidth + _separator)) width:itemWidth height:itemHeight];
    }];
}

// 设置 imageView 约束的方法
- (void)setImageView:(UIImageView *)imageView index:(NSInteger)index constraintsWithTop:(CGFloat)top leading:(CGFloat)leading width:(CGFloat)width height:(CGFloat)height {
    imageView.tag = index;
    NSLayoutConstraint *constraint = objc_getAssociatedObject(imageView, kJWZSudokuViewTopConstraintToken);
    constraint.constant = top;
    constraint = objc_getAssociatedObject(imageView, kJWZSudokuViewLeadingConstraintToken);
    constraint.constant = leading;
    constraint = objc_getAssociatedObject(imageView, kJWZSudokuViewWidthConstraintToken);
    constraint.constant = width;
    constraint = objc_getAssociatedObject(imageView, kJWZSudokuViewHeightConstraintToken);
    constraint.constant = height;
}

// 四个的时候，显示田字格，其余的时候显示九宫格
- (NSInteger)rowSizeForItemCount:(NSUInteger)count {
    switch (count) {
        case 1:
            return 1;
            break;
        case 4:
            return 2;
        default:
            return 3;
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width > 0) {
        [self layoutImageViews];
    }
}

- (NSArray<UIImageView *> *)allImageViews {
    return _contentViews;
}

// 点击图片的代理事件
- (void)tapAction:(UITapGestureRecognizer *)tap {
    if (_delegate && [_delegate respondsToSelector:@selector(sudokuView:didTouchOnImageView:atIndex:)]) {
        UIImageView *imageView = (UIImageView *)tap.view;
        [_delegate sudokuView:self didTouchOnImageView:imageView atIndex:imageView.tag];
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end

#pragma mark - Sudoku Wrapper View

@implementation JWZSudokuWrapperView

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *superView = self.superview;
    if (superView != nil && superView.translatesAutoresizingMaskIntoConstraints == YES) {
        CGRect frame = superView.frame;
        frame.size.height = self.bounds.size.height;
        superView.frame = frame;
    }
}

@end