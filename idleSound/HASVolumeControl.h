//
//  HASVolumeControl.h
//  idleSound
//
//  Created by Christopher Loessl on 10/13/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HASVolumeControl : NSObject

+ (float)volume;
+ (void)setVolume:(Float32)newVolume;

@end
