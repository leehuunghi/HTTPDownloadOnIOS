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

- (dispatch_queue_t)getQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("download_table_queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

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
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async([self getQueue], ^{
        [weakSelf.cellObjects insertObject:cellObject atIndex:0];
        [weakSelf.originCellObjects insertObject:cellObject atIndex:0];
        
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
    });
}

- (void)removeCell:(CellObjectModel *)cellObject {
    NSUInteger index = [_cellObjects indexOfObject:cellObject];
    if (index < _cellObjects.count) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async([self getQueue], ^{
            [weakSelf.cellObjects removeObjectAtIndex:index];
            [weakSelf.originCellObjects removeObject:cellObject];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
                [weakSelf checkEmpty];
            });
        });
    } else {
        
    }
}

- (void)reloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        [super reloadData];
    });
    
    [self checkEmpty];
}

- (void)checkEmpty {
    if (_cellObjects.count == 0) {
        NSUInteger errorCode =  DownloadErrorCodeFilterEmpty;
        if (_originCellObjects.count == 0) {
            _cellObjects = [NSMutableArray new];
            errorCode = DownloadErrorCodeEmpty;
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
    
    __weak __typeof(self) weakSelf = self;
    dispatch_async([self getQueue], ^{
        [weakSelf.cellObjects insertObject:weakSelf.infoObject atIndex:0];
        [self reloadData];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//        });
    });
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
        _cellObjects = [[NSMutableArray alloc] initWithArray:_originCellObjects];
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
