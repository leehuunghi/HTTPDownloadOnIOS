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

@property (strong, nonatomic) NSMutableArray<CellObjectModel *> *originCellObjects;

@end

@implementation DownloadTableView

@synthesize cellObjects = _cellObjects;

- (void)setCellObjects:(NSMutableArray *)cellObjects {
    _originCellObjects = cellObjects;
    _cellObjects = cellObjects;
    
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.dataSource = self;
    self.delegate = self;
    
    if (!_cellObjects) {
        _cellObjects = [NSMutableArray new];
        _originCellObjects = [NSMutableArray new];
    }
    [self reloadData];
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
    if (!cellObject) {
        return;
    }
    if (!_cellObjects) {
        _cellObjects = [NSMutableArray new];
    }
    if (!_originCellObjects) {
        _originCellObjects = [NSMutableArray new];
    }
    
    [_cellObjects insertObject:cellObject atIndex:0];
    if (_cellObjects != _originCellObjects) {
        [_originCellObjects insertObject:cellObject atIndex:0];
    }
    
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf insertRowsAtIndexPaths:@[[DownloadTableView headIndexPath]] withRowAnimation:UITableViewRowAnimationMiddle];
        if (weakSelf.error) {
            if (weakSelf.error.code == DownloadErrorCodeEmpty
                || weakSelf.error.code == DownloadErrorCodeFilterEmpty) {
                weakSelf.error = nil;
                [self removeCell:weakSelf.infoObject];
            }
        }
    });
}

- (void)removeCell:(CellObjectModel *)cellObject {
    NSUInteger index = [_cellObjects indexOfObject:cellObject];
    if (index < _cellObjects.count) {
        [_cellObjects removeObjectAtIndex:index];
        if (_cellObjects != _originCellObjects) {
            [_originCellObjects removeObject:cellObject];
        }
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
            [weakSelf checkEmpty];
        });
    } else {
        
    }
}

- (void)reloadData {
    [super reloadData];
    [self checkEmpty];
}

- (void)checkEmpty {
    if (_cellObjects.count == 0) {
        NSUInteger errorCode =  DownloadErrorCodeEmpty;
        if (_originCellObjects.count == 0) {
            _cellObjects = [NSMutableArray new];
            errorCode = DownloadErrorCodeFilterEmpty;
        }
        _error = [NSError errorWithDomain:DownloadErrorDomain code:errorCode userInfo:nil];
        [self errorCellWillDisplay];
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
        case DownloadErrorCodeFilterEmpty:
            _infoObject.messange = @"Empty";
            break;
        default:
            _infoObject.messange = [NSString stringWithFormat:@"Error: %ld", _error.code];
            break;
    }
    
    [_cellObjects insertObject:_infoObject atIndex:0];
    [self insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)moveCellToHead:(CellObjectModel *)cellObject {
    NSUInteger index = [_cellObjects indexOfObject:cellObject];
    NSIndexPath *indexPath = [DownloadTableView indexPathForIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        [cell setSelected:YES];
        
    });
    
//    if (index < [_cellObjects count]) {
//        [_cellObjects removeObjectAtIndex:index];
//        [_cellObjects insertObject:cellObject atIndex:0];
//        __weak __typeof(self) weakSelf = self;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf moveRowAtIndexPath:[DownloadTableView indexPathForIndex:index] toIndexPath:[DownloadTableView headIndexPath]];
//        });
//    }
}

#pragma mark - filter

- (void)filterWithCondition:(BOOL (^)(CellObjectModel *cellObject))condition {
    if (condition) {
        _cellObjects = [NSMutableArray new];
        for (CellObjectModel *object in _originCellObjects) {
            if (condition(object)) {
                [_cellObjects addObject:object];
            }
        }
    } else {
        _cellObjects = _originCellObjects;
    }
    [self reloadData];
    
}

#pragma mark - constant

+ (NSIndexPath *)headIndexPath {
    static NSIndexPath *indexPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    });
    return indexPath;
}

+ (NSIndexPath *)indexPathForIndex:(NSUInteger)index {
    return [NSIndexPath indexPathForRow:index inSection:0];
}

@end
