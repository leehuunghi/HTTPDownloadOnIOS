//
//  PriorityQueue.h
//  HTTPDownload
//
//  Created by CPU11360 on 8/2/18.
//  Copyright © 2018 CPU11367. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadEnumType.h"

@interface PriorityQueue : NSObject

- (void)addObject:(id)object;

- (void)addObject:(id)object withPriority:(DownloadPriority)priority;

- (id)dequeue;

- (void)removeObject;

- (void)removeObject:(dispatch_queue_t)queue;

- (NSInteger)count;

- (void)setPriorityForObject:(id)object withPriority:(DownloadPriority)priority;

- (void)removeObject:(id)object withPriority:(DownloadPriority)priority;

//- (bool)isContainObject:(id)object;

@end
