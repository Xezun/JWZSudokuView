//
//  ViewController.m
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import "ViewController.h"
#import "TableViewCell.h"

@interface ViewController () <JWZSudokuViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TableViewCell"];
    
    
    _dataArray = @[@"http://cdn.duitang.com/uploads/item/201408/13/20140813122725_8h8Yu.jpeg",
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
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    [cell.sudokuView setContentWithImageUrls:[_dataArray subarrayWithRange:NSMakeRange(0, indexPath.row)]];
    cell.label.text = [NSString stringWithFormat:@"%ld 张图片", indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat sodukuViewHeight = [JWZSudokuView heightForContentImageCount:indexPath.row totalWidth:200];
    if (sodukuViewHeight == 0) {
        return 40;
    }
    return  sodukuViewHeight + 20;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
