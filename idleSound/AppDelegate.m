//
//  AppDelegate.m
//  idleSound
//
//  Created by Christopher Loessl on 10/10/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

#import "AppDelegate.h"
#import "HASVolumeControl.h"
#import "common.h"
#import "Notifications.h"
#import "IdleManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) IdleManager *idleManager;
@property (nonatomic, strong) NSStatusItem* statusItem;
@property (assign, nonatomic) BOOL wasMutedBefore;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupMenuBarItem];
    self.idleManager = [[IdleManager alloc] init];
    [self registerObserver];
}

- (void)setupMenuBarItem {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setTitle:NSLocalizedString(@"S", @"Title of idleSound")];
    //    [self.statusItem setMenu:self.statusItemMenu];
    [self.statusItem setHighlightMode:YES];
}

- (void)registerObserver {
    NSNotificationCenter *notificationCenter;

	// Idle events are in the Adium notification center, posted by the AdiumIdleManager
	notificationCenter = [NSNotificationCenter defaultCenter];
    
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIMachineIdleUpdateNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIMachineIsActiveNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(notificationHandler:)
							   name:AIMachineIsIdleNotification
							 object:nil];
}

- (void)notificationHandler:(NSNotification *)notification {
	NSString *notificationName = [notification name];
    
    // Start events
	if ([notificationName isEqualToString:AIMachineIsIdleNotification]) {
        NSLog(@"Machine is idle");
        self.wasMutedBefore = [HASVolumeControl isMuted];
        if (!self.wasMutedBefore) {
            [HASVolumeControl setMute];
        }
    }
    
    // Updates every second
	if ([notificationName isEqualToString:AIMachineIdleUpdateNotification]) {
//        NSLog(@"Machine update timer");
    }
    
    // End events
	if ([notificationName isEqualToString:AIMachineIsActiveNotification]) {
        NSLog(@"Machine is not idle any longer");
        if (!self.wasMutedBefore) {
            [HASVolumeControl unMuted];
        }
    }
}

@end
