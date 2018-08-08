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

- (void)addObject:(id)object {
    [self addObject:object withPriority:DownloadPriorityMedium];
}

- (void)addObject:(id)object withPriority:(DownloadPriority)priority {
    if(object) {
        __weak typeof (self) weakSelf = self;
            switch (priority) {
                case DownloadPriorityHigh: {
                    dispatch_barrier_async(self.concurrentQueue, ^{
                        [weakSelf.arrayHigh addObject:object];
                    });
                    break;
                }
                case DownloadPriorityMedium: {
                    dispatch_barrier_async(self.concurrentQueue, ^{
                        [weakSelf.arrayMedium addObject:object];
                    });
                    break;
                }
                case DownloadPriorityLow: {
                    dispatch_barrier_async(self.concurrentQueue, ^{
                        [weakSelf.arrayLow addObject:object];
                    });
                    break;
                }
                default:
                    NSLog(@"No priority");
                    break;
            }
    }
}

- (void)removeObject {
    __weak typeof(self)weakSelf = self;
    dispatch_barrier_async(self.concurrentQueue, ^{
        if ([weakSelf.arrayHigh count]) {
            [weakSelf.arrayHigh removeLastObject];
        } else if ([weakSelf.arrayMedium count]) {
            [weakSelf.arrayMedium removeLastObject];
        } else if ([weakSelf.arrayLow count]) {
            [weakSelf.arrayLow removeLastObject];
        } else {
            NSLog(@"Nothing in queue for remove!");
        }
    });
}

- (id)getObjectFromQueue {
    __weak typeof(self)weakSelf = self;
    __block id object = nil;
    dispatch_barrier_sync(self.concurrentQueue, ^{
        if ([weakSelf.arrayHigh count]) {
            object = [weakSelf.arrayHigh lastObject];
        } else if ([weakSelf.arrayMedium count]) {
            object = [weakSelf.arrayMedium lastObject];
        } else if ([weakSelf.arrayLow count]) {
            object = [weakSelf.arrayLow lastObject];
        } else {
            NSLog(@"Nothing in queue for get!");
        }
    });
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
