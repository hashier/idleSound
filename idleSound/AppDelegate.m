//
//  AppDelegate.m
//  idleSound
//
//  Created by Christopher Loessl on 10/10/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

#import "AppDelegate.h"
#import "HASVolumeControl.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"Vol: %f", [HASVolumeControl volume]);
    [HASVolumeControl setVolume:0.2];
    NSLog(@"Vol: %f", [HASVolumeControl volume]);
}

@end
