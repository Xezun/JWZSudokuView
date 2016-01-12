//
//  TableViewCell.h
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWZSudokuView.h"

@interface TableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet JWZSudokuView *sudokuView;
@property (weak, nonatomic) IBOutlet UILabel *label;

- (CGFloat)heightForTableView:(UITableView *)tableView;

@end
