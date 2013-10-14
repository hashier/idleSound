//
//  IdleManager.h
//  idleSound
//
//  Created by Christopher Loessl on 10/13/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IdleManager : NSObject

// properties
@property (assign, nonatomic) NSUInteger machineIdleThreshold; // default 30min

// public methods
- (id)init;

@end
