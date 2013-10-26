//
//  IdleManager.h
//  idleSound
//
//  Created by Christopher Loessl on 10/13/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

// Used AdiumIdleManager as basis for this class
// https://hg.adium.im/adium/file/8f48d8e917b5/Source/AdiumIdleManager.m

#import <Foundation/Foundation.h>

@interface IdleManager : NSObject

// properties
@property (assign, nonatomic) NSUInteger machineIdleThreshold; // default 30min

// public methods
- (id)init;
- (void)disable;
- (void)enable;
- (void)monitorScreenChanges;
- (void)stopMonitoringScreenChanges;

@end
