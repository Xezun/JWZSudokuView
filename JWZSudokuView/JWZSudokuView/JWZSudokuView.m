//
//  JWZSudokuView.m
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import <objc/runtime.h>
#import "JWZSudokuView.h"
#import "UIImageView+WebCache.h"

static void const *const kJWZSudokuViewWidthConstraintToken = &kJWZSudokuViewWidthConstraintToken;
static void const *const kJWZSudokuViewLeadingConstraintToken = &kJWZSudokuViewLeadingConstraintToken;
static void const *const kJWZSudokuViewTopConstraintToken = &kJWZSudokuViewTopConstraintToken;

@interface JWZSudokuWrapperView : UIView

@end

@interface JWZSudokuView ()

@property (nonatomic, strong) JWZSudokuWrapperView *wrapperView;                    // 容器视图
@property (nonatomic, weak) NSLayoutConstraint *wrapperHeightConstraint;            // 容器视图的高度约束
@property (nonatomic, strong) NSMutableArray<UIImageView *> *contentViews;          // 正在显示的图片
@property (nonatomic, strong) NSMutableArray<UIImageView *> *reusableContentViews;  // 重用池

@end

@implementation JWZSudokuView

// 计算每个小图的宽度
+ (CGFloat)widthWithTotalWith:(CGFloat)totalWidth separator:(CGFloat)separator {
    return (totalWidth - separator * 2) / 3.0;
}

// 计算整个视图的高度
+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator {
   return [self heightForContentImageCount:count width:[self widthWithTotalWith:totalWidth separator:separator] separator:separator aspectRatio:1.0];
}

+ (CGFloat)heightForContentImageCount:(NSUInteger)count totalWidth:(CGFloat)totalWidth separator:(CGFloat)separator aspectRatio:(CGFloat)aspectRatio {
    return [self heightForContentImageCount:count width:[self widthWithTotalWith:totalWidth separator:separator] separator:separator aspectRatio:aspectRatio];
}

+ (CGFloat)heightForContentImageCount:(NSUInteger)count width:(CGFloat)width separator:(CGFloat)separator {
    return [self heightForContentImageCount:count width:width separator:separator aspectRatio:1.0];
}

+ (CGFloat)heightForContentImageCount:(NSUInteger)count width:(CGFloat)width separator:(CGFloat)separator aspectRatio:(CGFloat)aspectRatio {
    NSInteger totalRow = ceil(MIN(9, count) / 3.0); // 进位取整，总行数
    return (totalRow > 0 ? ((totalRow) * (width / aspectRatio + separator) - separator) : 0);
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame aspectRatio:1.0];
}

- (instancetype)initWithFrame:(CGRect)frame aspectRatio:(CGFloat)aspectRatio {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        _aspectRatio = aspectRatio;
    }
    return self;
}

#pragma mark - 属性

- (CGFloat)separator {
    if (_separator > 0) {
        return _separator;
    }
    _separator = 1.0;
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

#pragma mark - 方法

// 从重用池取一个 ImageView
- (UIImageView *)dequeueReusableContentView {
    UIImageView *imageView = [self.reusableContentViews lastObject];
    if (imageView != nil) {
        imageView.hidden = NO;
        [_reusableContentViews removeObject:imageView];
    } else {
        imageView = [self createImageView];
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
- (UIImageView *)createImageView {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.backgroundColor = [UIColor lightGrayColor];
    imageView.userInteractionEnabled = YES;
    imageView.layer.borderColor = [UIColor colorWithWhite:0.97 alpha:1].CGColor;
    imageView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [imageView addGestureRecognizer:tap];
    [self.wrapperView addSubview:imageView];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeTop) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:top];
    objc_setAssociatedObject(imageView, kJWZSudokuViewTopConstraintToken, top, OBJC_ASSOCIATION_RETAIN);
    
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeLeading) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeLeading) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:leading];
    objc_setAssociatedObject(imageView, kJWZSudokuViewLeadingConstraintToken, leading, OBJC_ASSOCIATION_RETAIN);
    
    NSLayoutConstraint *aspectRatio = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:imageView attribute:(NSLayoutAttributeHeight) multiplier:_aspectRatio constant:0];
    [imageView addConstraint:aspectRatio];
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeWidth) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
    [imageView addConstraint:width];
    objc_setAssociatedObject(imageView, kJWZSudokuViewWidthConstraintToken, width, OBJC_ASSOCIATION_RETAIN);
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
    }else if (oldContentCount > newContentCount) {
        for (NSInteger i = oldContentCount - 1; i >= newContentCount; i --) {
            UIImageView *imageView = _contentViews[i];
            [_contentViews removeObjectAtIndex:i];
            [self queueReusableContentView:imageView];  // 回收 Image View
        }
    }
}

// 添加图片
- (void)setContentWithImages:(NSArray<UIImage *> *)images {
    [self setContentWithCount:images.count];
    [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.image = images[idx];
    }];
    [self setNeedsLayout];
}

// 添加网络图片
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls {
    [self setContentWithImageUrls:urls placeholder:nil];
}

// 添加网络图片，在图片下载前使用占位图
- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)image {
    [self setContentWithCount:urls.count];
    [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj sd_setImageWithURL:[NSURL URLWithString:urls[idx]] placeholderImage:image];
    }];
    [self setNeedsLayout];
}

- (void)setContentWithModels:(NSArray<id<JWZSudokuViewModelRTF>> *)models placeholder:(UIImage *)image {
    [self setContentWithCount:models.count];
    [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<JWZSudokuViewModelRTF> model = [models objectAtIndex:idx];
        NSURL *url = [NSURL URLWithString:[model valueForKey:[model imageUrlKey]]];
        [obj sd_setImageWithURL:url placeholderImage:image];
    }];
    [self setNeedsLayout];
}

- (void)layoutImageViews {
    CGFloat width = [[self class] widthWithTotalWith:self.bounds.size.width separator:self.separator];
    CGFloat height = width / _aspectRatio;
    NSInteger count = _contentViews.count;
    self.wrapperHeightConstraint.constant = [[self class] heightForContentImageCount:count width:width separator:_separator aspectRatio:_aspectRatio];
    NSInteger rowSize = (count == 4 ? 2 : 3); // 四个的时候，显示田字格，其余的时候显示九宫格
    [_contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.tag = idx;
        NSInteger row = idx / rowSize;
        NSInteger col = idx % rowSize;
        NSLayoutConstraint *constraint = objc_getAssociatedObject(obj, kJWZSudokuViewTopConstraintToken);
        constraint.constant = (height  + _separator) * row;
        constraint = objc_getAssociatedObject(obj, kJWZSudokuViewWidthConstraintToken);
        constraint.constant = width;
        constraint = objc_getAssociatedObject(obj, kJWZSudokuViewLeadingConstraintToken);
        constraint.constant = (width + _separator) * col;
    }];
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

- (void)didReceiveMemoryWarning {
    NSArray *array = _reusableContentViews;
    _reusableContentViews = nil;
    [array enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

@end


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