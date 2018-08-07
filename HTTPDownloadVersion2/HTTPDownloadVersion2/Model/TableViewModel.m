//
//  TableViewModel.m
//  HTTPDownload
//
//  Created by CPU11367 on 8/1/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "TableViewModel.h"
#import "CellObjectModel.h"
#import "TableViewCellModel.h"

@implementation TableViewModel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setCellObjects:(NSMutableArray *)cellObjects {
    _cellObjects = cellObjects;
    self.dataSource = self;
    self.delegate = self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellObjectModel *cellObject = _cellObjects[indexPath.row];
    Class cellClass = [cellObject cellClass];
    if ([cellClass isSubclassOfClass
         :[TableViewCellModel class]]) {
        TableViewCellModel *cell = [cellClass tableView:tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            [cell shouldUpdateWithObject:cellObject];
            return cell;
        }
    }
    return [UITableViewCell new];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellObjects count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellObjectModel *cellObject = _cellObjects[indexPath.row];
    return [cellObject tableView:tableView heightForRowAtIndexPath:indexPath];
}

@end
