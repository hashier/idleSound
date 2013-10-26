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

// properties
@property (strong, nonatomic) IdleManager *idleManager;
@property (strong, nonatomic) NSStatusItem* statusItem;
@property (assign, nonatomic) BOOL wasMutedBefore;
@property (strong, nonatomic) NSMenuItem *activeMenuItem;
@property (weak) IBOutlet NSMenuItem *thirtyMenuItem;

// outlets
@property (weak) IBOutlet NSMenu *statusItemMenu;
@property (weak) IBOutlet NSMenuItem *quit;

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
//    http://stackoverflow.com/a/8401132/1953914
//    In application xib, select the window object, and you will see "Visible at Launch" in Attributes Inspector.
    _window.isVisible = NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.idleManager = [[IdleManager alloc] init];
    [self thirty:self.thirtyMenuItem];
    [self setupMenuBarItem];
    [self registerObserver];
    [self language];
}

#pragma mark - Layout

- (void)setupMenuBarItem {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setTitle:NSLocalizedString(@"S", @"Title of idleSound")];
    [self.statusItem setMenu:self.statusItemMenu];
    [self.statusItem setHighlightMode:YES];
}

#pragma mark - Translations

- (void)language {
    self.quit.title = NSLocalizedString(@"Quit", @"Click to quit the app");
}

#pragma mark - Notification

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
        self.wasMutedBefore = [HASVolumeControl isMuted];
        if (!self.wasMutedBefore) {
            [HASVolumeControl mute];
        }
    }
    
    // Updates every second
	if ([notificationName isEqualToString:AIMachineIdleUpdateNotification]) {
//        NSLog(@"Machine update timer");
    }
    
    // End events
	if ([notificationName isEqualToString:AIMachineIsActiveNotification]) {
        if (!self.wasMutedBefore) {
            [HASVolumeControl unmute];
        }
    }
}

#pragma mark - MenuItems

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)about:(id)sender {
    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *versionBuildString = [NSString stringWithFormat:@"Version: %@ (%@)", appVersionString, appBuildString];
	NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"idleSound\n\nidleSound is free and open source software which automatically mutes your Mac after a specified time.", @"\n\nCopyright (C) 2013 Christopher Loessl\n\n", versionBuildString];
	NSAlert *alert = [NSAlert alertWithMessageText:msg
									 defaultButton:@"Close"
								   alternateButton:@"Source Code and Bugtracker"
									   otherButton:nil
						 informativeTextWithFormat:@""];
    
	if ([alert runModal] == NSAlertAlternateReturn) {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://loessl.org"]];
	}
}

- (IBAction)sixty:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 3600;
    [sender setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = sender;
}

- (IBAction)thirty:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 1800;
    [sender setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = sender;
}

- (IBAction)fifteen:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 900;
    [sender setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = sender;
}

- (IBAction)five:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 300;
    [sender setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = sender;
}

- (IBAction)noTime:(NSMenuItem *)sender {
    [self.idleManager stopMonitoringScreenChanges];
    [sender setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = sender;
}

@end
