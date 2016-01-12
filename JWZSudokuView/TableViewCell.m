//
//  TableViewCell.m
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat)heightForTableView:(UITableView *)tableView {
    self.frame = tableView.bounds;
    [self layoutIfNeeded];
    CGFloat height = CGRectGetMaxY(self.sudokuView.frame) + 10;
    return (height > 40.0 ? height : 40.0);
}

@end
