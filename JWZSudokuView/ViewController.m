//
//  ViewController.m
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"

@interface JWZCellModel : NSObject

@property (nonatomic, strong) NSArray<NSString *> *urls;
@property (nonatomic) CGFloat cellHeight;

@end

@implementation JWZCellModel

@end

@interface ViewController () <JWZSudokuViewDelegate, UITableViewDataSource, UITableViewDelegate, JWZSudokuViewOptimizer>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray<JWZCellModel *> *dataArray;

@property (nonatomic) CGFloat cellHeight;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 100;
    
    NSArray<NSString *> *array = @[@"http://h.hiphotos.baidu.com/image/pic/item/4ec2d5628535e5dd2820232370c6a7efce1b623a.jpg",
                   @"http://v1.qzone.cc/avatar/201403/30/09/33/533774802e7c6272.jpg%21200x200.jpg",
                   @"http://img4.duitang.com/uploads/item/201409/16/20140916103123_343c3.jpeg",
                   @"http://v1.qzone.cc/avatar/201407/25/20/52/53d253192be47412.jpg%21200x200.jpg",
                   @"http://cdn.duitang.com/uploads/item/201408/13/20140813122725_8h8Yu.jpeg",
                   @"http://v1.qzone.cc/avatar/201403/30/09/33/533774802e7c6272.jpg%21200x200.jpg",
                   @"http://img4.duitang.com/uploads/item/201409/16/20140916103123_343c3.jpeg",
                   @"http://v1.qzone.cc/avatar/201407/25/20/52/53d253192be47412.jpg%21200x200.jpg",
                   @"http://cdn.duitang.com/uploads/item/201408/13/20140813122725_8h8Yu.jpeg",
                   @"http://v1.qzone.cc/avatar/201403/30/09/33/533774802e7c6272.jpg%21200x200.jpg",
                   @"http://img4.duitang.com/uploads/item/201409/16/20140916103123_343c3.jpeg",
                   @"http://v1.qzone.cc/avatar/201407/25/20/52/53d253192be47412.jpg%21200x200.jpg"
                   ];
    
    NSMutableArray *array2 = [NSMutableArray array];
    for (NSInteger i = 0; i < array.count; i ++) {
        NSArray *tmp = [array subarrayWithRange:NSMakeRange(0, i)];
        JWZCellModel *model = [[JWZCellModel alloc] init];
        model.urls = tmp;
        [array2 addObject:model];
    }
    self.dataArray = array2;
}

- (void)sudokuView:(JWZSudokuView *)sudokuView didTouchOnImageView:(UIImageView *)imageView atIndex:(NSInteger)index {
    NSLog(@"%ld", index);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TableViewCell" owner:nil options:nil] lastObject];
    }
    
    JWZCellModel *model = [self.dataArray objectAtIndex:indexPath.row];
    cell.sudokuView.optimizer = self;
    [cell.sudokuView setContentWithImageUrls:model.urls placeholder:nil];
    cell.label.text = [NSString stringWithFormat:@"%ld 张图片", indexPath.row];
    
    model.cellHeight = [cell heightForTableView:tableView];
//    NSLog(@"A: %ld, cellHeight: %f", indexPath.row, model.cellHeight);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    JWZCellModel *model = [self.dataArray objectAtIndex:indexPath.row];
//    NSLog(@"B: %ld, cellHeight: %f", indexPath.row, model.cellHeight);
    return  model.cellHeight;
}

- (CGFloat)sudokuView:(JWZSudokuView *)sudokuView widthForSingleImageView:(UIImageView *)imageView {
    return 1280;
}

- (CGFloat)sudokuView:(JWZSudokuView *)sudokuView heightForSingleImageView:(UIImageView *)imageView {
    return 853;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
