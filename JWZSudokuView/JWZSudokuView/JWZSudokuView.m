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
    return width / height;
}

static inline CGFloat JWZAspectRatioFromCGSize(CGSize size) {
    return JWZAspectRatio(size.width, size.height);
}

static void const *const kJWZSudokuViewWidthConstraintToken   = &kJWZSudokuViewWidthConstraintToken;// 宽度
static void const *const kJWZSudokuViewHeightConstraintToken  = &kJWZSudokuViewHeightConstraintToken;// 高度
static void const *const kJWZSudokuViewLeadingConstraintToken = &kJWZSudokuViewLeadingConstraintToken;// item 距左边
static void const *const kJWZSudokuViewTopConstraintToken     = &kJWZSudokuViewTopConstraintToken;// item 距右边
static void const *const kJWZSudokuViewUrlStringToken          = &kJWZSudokuViewUrlStringToken;// item 距右边

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
        _optimizeForSingleImage = (_optimizer != nil);
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
    
    // 距父视图的上边
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeTop) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:top];
    objc_setAssociatedObject(imageView, kJWZSudokuViewTopConstraintToken, top, OBJC_ASSOCIATION_RETAIN);
    
    // 距父视图的左边
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeLeading) relatedBy:(NSLayoutRelationEqual) toItem:_wrapperView attribute:(NSLayoutAttributeLeading) multiplier:1.0 constant:0];
    [_wrapperView addConstraint:leading];
    objc_setAssociatedObject(imageView, kJWZSudokuViewLeadingConstraintToken, leading, OBJC_ASSOCIATION_RETAIN);
    
    // 高度约束
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:imageView attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1.0 constant:0];
    [imageView addConstraint:height];
    objc_setAssociatedObject(imageView, kJWZSudokuViewHeightConstraintToken, height, OBJC_ASSOCIATION_RETAIN);
    
    // 宽
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
    NSInteger count = images.count;
    [self setContentWithCount:images.count];
    if (count > 0) {
        CGFloat cutAspect = ((count == 1 && _optimizeForSingleImage) ? JWZAspectRatioFromCGSize(images.firstObject.size) : self.aspectRatio);
        [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.image = [self imageFromImage:images[idx] cutAspect:cutAspect];
        }];
    }
    [self setNeedsLayout];
}

- (void)setContentWithImages:(NSArray<UIImage *> *)images optimizeForSingleImage:(BOOL)optimize {
    _optimizeForSingleImage = optimize;
    [self setContentWithImages:images];
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
        // 先设置图片，后设置的代理，将使单图优化无效
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        CGFloat cutAspect = (count == 1 ? [self aspectRatioForSingleImageView:_contentViews.firstObject] : self.aspectRatio);
        [self.contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *url          = [urls objectAtIndex:idx];
            NSString *cacheUrl     = [url stringByAppendingString:@"?com.JWZ.sudokuView.cache"];
            UIImage *cacheImage    = [imageCache imageFromDiskCacheForKey:cacheUrl];
            if (cacheImage != nil) {
                obj.image = [self imageFromImage:cacheImage cutAspect:cutAspect];
            } else {
                UIImage *image = [imageCache imageFromDiskCacheForKey:url];
                if (image != nil) {
                    UIImage *newImage = [self imageFromImage:image cutAspect:cutAspect];
                    obj.image = newImage;
                    if (newImage != image) {
                        [imageCache storeImage:newImage forKey:cacheUrl];
                    }
                } else {
                    obj.image = [self imageFromImage:placeholder cutAspect:cutAspect];
                    [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:url] options:(0) progress:NULL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                        if (image != nil) {
                            UIImage *newImage = [self imageFromImage:image cutAspect:cutAspect];
                            if (newImage != image) {
                                [imageCache storeImage:newImage forKey:cacheUrl];
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                obj.image = newImage;
                            });
                        }
                    }];
                }
            }
        }];
    }
    [self setNeedsLayout];
}

- (void)setContentWithImageUrls:(NSArray<NSString *> *)urls placeholder:(UIImage *)placeholder optimizer:(id<JWZSudokuViewOptimizer>)optimizer {
    [self setOptimizer:optimizer];
    [self setContentWithImageUrls:urls placeholder:placeholder];
}

#pragma mark - 布局图片

- (void)layoutImageViews {
    NSInteger itemCount = _contentViews.count;
    CGFloat totalWidth  = self.bounds.size.width;
    if (itemCount > 1 || !_optimizeForSingleImage) {
        CGFloat totalHeight = [[self class] heightForItemCount:itemCount totalWidth:totalWidth separator:self.separator aspectRatio:self.aspectRatio];
        CGFloat itemWidth   = [[self class] itemWidthWithTotalWidth:totalWidth itemCount:itemCount separator:_separator];
        CGFloat itemHeight  = itemWidth / _aspectRatio;
        // 每行小图的个数
        NSInteger rowSize = [self rowSizeForItemCount:itemCount];
        // 设置视图的高度
        self.wrapperHeightConstraint.constant = totalHeight;
        [_contentViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger row = idx / rowSize;
            NSInteger col = idx % rowSize;
            [self setImageView:obj index:idx constraintsWithTop:(row * (itemHeight  + _separator)) leading:(col * (itemWidth + _separator)) width:itemWidth height:itemHeight];
        }];
    } else if (itemCount == 1) {
        UIImageView *imageView = [_contentViews firstObject];
        CGFloat aspectRatio = 0;
        if (_optimizer != nil) {
            aspectRatio = [self aspectRatioForSingleImageView:imageView];
        } else {
            aspectRatio = JWZAspectRatioFromCGSize(imageView.image.size);
        }
        CGSize displaySize  = [self displaySizeForSingleImageView:imageView totalWidth:totalWidth aspectRatio:aspectRatio];
        self.wrapperHeightConstraint.constant = displaySize.height;
        [self setImageView:imageView index:0 constraintsWithTop:0 leading:0 width:displaySize.width height:displaySize.height];
    } else {
        self.wrapperHeightConstraint.constant = 0;
    }
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

// 单张图片的时候，计算图片实际显示的大小
- (CGSize)displaySizeForSingleImageView:(UIImageView *)imageView totalWidth:(CGFloat)totalWidth aspectRatio:(CGFloat)aspectRatio {
    CGFloat maxWidth   = totalWidth * self.maxScaleForSingleImage;
    CGFloat maxHeight  = maxWidth;
    if (aspectRatio > 1) {
        return CGSizeMake(maxWidth, maxWidth / aspectRatio);
    } else {
        return CGSizeMake(maxHeight * aspectRatio, maxHeight);
    }
}

// 计算单图模式下，获取图片的宽高比
- (CGFloat)aspectRatioForSingleImageView:(UIImageView *)imageView {
    if (_optimizeForSingleImage && _optimizer != nil) {
        // 图片原始大小，通过代理方法获取
        CGFloat oWidth = 0, oHeight = 0;
        oWidth  = [_optimizer sudokuView:self widthForSingleImageView:imageView];
        oHeight = [_optimizer sudokuView:self heightForSingleImageView:imageView];
        // 图片原始宽高比
        CGFloat oAspect   = JWZAspectRatio(oWidth, oHeight);
        // 宽高比最大值和最小值
        CGFloat maxAspect = self.maxScaleForSingleImage / self.minScaleForSingleImage;
        CGFloat minAspect = 1.0 / maxAspect;
        if (oAspect > maxAspect) {
            return maxAspect;
        } else if (oAspect < minAspect) {
            return minAspect;
        }
        return oAspect;
    } else {
        return self.aspectRatio;
    }
}

// 从图片中，截出出某一比例的图片
- (UIImage *)imageFromImage:(UIImage *)image cutAspect:(CGFloat)cutAspect {
    if (image == nil) {
        return nil;
    }
    CGSize imageSize = image.size;
    CGFloat imageAspect = JWZAspectRatioFromCGSize(imageSize);
    if (ABS(imageAspect - cutAspect) < 0.1) {
        return image;
    }
    CGFloat scale = image.scale;
    imageSize.width *= scale;
    imageSize.height *= scale;  // 裁剪图片是用的是像素，要把点转换成像素
    CGRect cutRect = CGRectZero;
    if (cutAspect < imageAspect) {
        cutRect.size.height = imageSize.height;
        cutRect.size.width = cutRect.size.height * cutAspect;
        cutRect.origin.x = (imageSize.width - cutRect.size.width) / 2.0;
    } else {
        cutRect.size.width = imageSize.width;
        cutRect.size.height = cutRect.size.width / cutAspect;
        cutRect.origin.y = (imageSize.height - cutRect.size.height) / 2.0;
    }
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, cutRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    // 缓存起来
    NSString *cacheUrl = objc_getAssociatedObject(image, kJWZSudokuViewUrlStringToken);
    if (cacheUrl != nil) {
        SDImageCache *imageCache = [SDImageCache sharedImageCache];
        [imageCache storeImage:newImage forKey:cacheUrl];
    }
    return newImage;
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