//
//  DownloadTableView.m
//  HTTPDownload
//
//  Created by CPU11367 on 7/31/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "DownloadTableView.h"
#import "TableViewCellModel.h"
#import "InfomationTableViewObject.h"

@interface DownloadTableView()

@property (strong, nonatomic) InfomationTableViewObject *infoObject;
@end

@implementation DownloadTableView

@synthesize cellObjects = _cellObjects;

- (void)setCellObjects:(NSMutableArray *)cellObjects {
    _cellObjects = cellObjects;
    
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.dataSource = self;
    self.delegate = self;
    
    if (!_cellObjects) {
        _cellObjects = [NSMutableArray new];
    }
    if (_cellObjects.count == 0) {
        _error = [NSError errorWithDomain:DownloadErrorDomain code:DownloadErrorCodeEmpty userInfo:nil];
        [self errorCellWillDisplay];
    }
    else {
        [self reloadData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CellObjectModel *cellObject = _cellObjects[indexPath.row];
    Class cellClass = [cellObject cellClass];
    if ([cellClass isSubclassOfClass:[TableViewCellModel class]]) {
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

- (void)addCell:(CellObjectModel *)cellObject {
    if (cellObject) {
        [_cellObjects insertObject:cellObject atIndex:0];
    }
    [self insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationMiddle];
    
    if (_error) {
        if (_error.code == DownloadErrorCodeEmpty) {
            _error = nil;
            [self removeCell:_infoObject];
        }
    }
    
    
}

- (void)removeCell:(CellObjectModel *)cellObject {
    NSUInteger index = [_cellObjects indexOfObject:cellObject];
    if (index < _cellObjects.count) {
        [_cellObjects removeObjectAtIndex:index];
        [self deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        if (_cellObjects.count == 0) {
            _error = [NSError errorWithDomain:DownloadErrorDomain code:DownloadErrorCodeEmpty userInfo:nil];
            [self errorCellWillDisplay];
        }
    } else {
        
    }
}


- (void)errorCellWillDisplay {
    if (!_error) {
        return;
    }
    if (!_infoObject) {
       _infoObject = [InfomationTableViewObject new];
    }
    
    switch (_error.code) {
        case DownloadErrorCodeEmpty:
            _infoObject.messange = @"History download is empty";
            break;
        default:
            _infoObject.messange = [NSString stringWithFormat:@"Error: %ld", _error.code];
            break;
    }
    
    [_cellObjects insertObject:_infoObject atIndex:0];
    [self insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}
@end
