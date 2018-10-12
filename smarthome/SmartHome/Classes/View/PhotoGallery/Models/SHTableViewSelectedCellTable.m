//
//  SHTableViewSelectedCellTable.m
//  SmartHome
//
//  Created by ZJ on 2017/5/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHTableViewSelectedCellTable.h"

@implementation SHTableViewSelectedCellTable

+ (instancetype)selectedCellTableWithParameters:(NSMutableArray *)nSelectedCells andCount:(NSUInteger)nCount {
    SHTableViewSelectedCellTable *table = [[SHTableViewSelectedCellTable alloc] init];
    table.selectedCells = nSelectedCells;
    table.count = nCount;
    
    return table;
}

@end
