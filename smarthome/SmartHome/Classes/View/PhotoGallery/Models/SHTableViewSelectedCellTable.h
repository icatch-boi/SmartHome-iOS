//
//  SHTableViewSelectedCellTable.h
//  SmartHome
//
//  Created by ZJ on 2017/5/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHTableViewSelectedCellTable : NSObject

@property(nonatomic) NSMutableArray *selectedCells;
@property(nonatomic) NSUInteger count;

+ (instancetype)selectedCellTableWithParameters:(NSMutableArray *)nSelectedCells andCount:(NSUInteger)nCount;

@end
