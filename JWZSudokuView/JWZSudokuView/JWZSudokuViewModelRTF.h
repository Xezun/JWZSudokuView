//
//  JWZSudokuViewModelRTF.h
//  JWZSudokuView
//
//  Created by J. W. Z. on 15/12/26.
//  Copyright © 2015年 J. W. Z. All rights reserved.
//

// 这个实际上是 KVC ，告诉 JWZSudokuView 从 Model 的哪个属性中取值

#import <Foundation/Foundation.h>

@protocol JWZSudokuViewModelRTF <NSObject>

@required
- (NSString *)imageUrlKey;
- (id)valueForKey:(NSString *)key;

@end
