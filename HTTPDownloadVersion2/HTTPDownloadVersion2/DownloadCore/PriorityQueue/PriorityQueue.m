//
//  PriorityQueue.m
//  HTTPDownload
//
//  Created by CPU11360 on 8/2/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import "PriorityQueue.h"

@interface PriorityQueue()
@property (strong, nonatomic) NSMutableArray *arrayHigh;
@property (strong, nonatomic) NSMutableArray *arrayMedium;
@property (strong, nonatomic) NSMutableArray *arrayLow;
@property (strong, nonatomic) dispatch_queue_t concurrentQueue;
@end

@implementation PriorityQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        _arrayHigh = [[NSMutableArray alloc] init];
        _arrayMedium = [[NSMutableArray alloc] init];
        _arrayLow = [[NSMutableArray alloc] init];
        _concurrentQueue = dispatch_queue_create("concurrent_queue_for_priority_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)addObject:(id)object withPriority:(Priority)priority {
    if(object && priority) {
        __weak typeof (self) weakSelf = self;
        switch (priority) {
            case High: {
                dispatch_barrier_async(self.concurrentQueue, ^{
                    [weakSelf.arrayHigh addObject:object];
                });
                break;
            }
            case Medium: {
                dispatch_barrier_async(self.concurrentQueue, ^{
                    [weakSelf.arrayMedium addObject:object];
                });
                break;
            }
            case Low: {
                dispatch_barrier_async(self.concurrentQueue, ^{
                    [weakSelf.arrayLow addObject:object];
                });
                break;
            }
            default:
                break;
        }
    }
}

- (void)removeObject {
    __weak typeof(self)weakSelf = self;
    if ([_arrayHigh count]) {
        dispatch_barrier_async(self.concurrentQueue, ^{
            [weakSelf.arrayHigh removeLastObject];
        });
    } else if ([_arrayMedium count]) {
        dispatch_barrier_async(self.concurrentQueue, ^{
            [weakSelf.arrayMedium removeLastObject];
        });
    } else if ([_arrayLow count]) {
        dispatch_barrier_async(self.concurrentQueue, ^{
            [weakSelf.arrayLow removeLastObject];
        });
    } else {
        NSLog(@"Nothing in queue for remove!");
    }
}

- (id)getObjectFromQueue {
    __weak typeof(self)weakSelf = self;
    __block id object = nil;
    if ([_arrayHigh count]) {
        dispatch_barrier_sync(self.concurrentQueue, ^{
            object = [weakSelf.arrayHigh lastObject];
        });
    } else if ([_arrayMedium count]) {
        dispatch_barrier_sync(self.concurrentQueue, ^{
            object = [weakSelf.arrayMedium lastObject];
        });
    } else if ([_arrayLow count]) {
        dispatch_barrier_sync(self.concurrentQueue, ^{
            object = [weakSelf.arrayLow lastObject];
        });
    } else {
        NSLog(@"Nothing in queue for get!");
    }
    return object;
}

- (NSInteger)count {
    __block unsigned long count = 0;
    __weak typeof(self)weakSelf = self;
    dispatch_sync(self.concurrentQueue, ^{
        count += [weakSelf.arrayHigh count];
        count += [weakSelf.arrayMedium count];
        count += [weakSelf.arrayLow  count];
    });
    return count;
}

@end
