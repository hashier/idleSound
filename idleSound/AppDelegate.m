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

// outlets
@property (weak) IBOutlet NSMenu *statusItemMenu;
@property (weak) IBOutlet NSMenuItem *quit;
@property (weak) IBOutlet NSMenuItem *thirtyMenuItem;
@property (weak) IBOutlet NSMenuItem *screenStateMenuItem;

@end

@implementation AppDelegate

#define kSettingsIdleTime @"org.loessl.idleSound.settings.idleTime"
#define kSettingsFade @"org.loessl.idleSound.settings.fade"
#define kSettingsScreenState @"org.loessl.idleSound.settings.screenState"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DLog(@"Version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    // enable sudden process termination
    [[NSProcessInfo processInfo] enableSuddenTermination];
    
    self.idleManager = [[IdleManager alloc] init];
    
    [self setupMenuBarItem];
    [self settings];
    [self registerObserver];
    [self language];
}

- (void)settings
{
    // time
    [self thirty:self.thirtyMenuItem];
    
    // screen state
    BOOL screenStateIdle = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsScreenState];
    [self.idleManager screenStateIdle:screenStateIdle];
    screenStateIdle ? [self.screenStateMenuItem setState:NSOnState] : [self.screenStateMenuItem setState:NSOffState];
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
    } else if ([notificationName isEqualToString:AIMachineIdleUpdateNotification]) {
        // Updates every second
//        NSLog(@"Machine update timer");
    } else if ([notificationName isEqualToString:AIMachineIsActiveNotification]) {
        // End events
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
    [self changeActiveTo:sender];
}

- (IBAction)thirty:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 1800;
    [self changeActiveTo:sender];
}

- (IBAction)fifteen:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 900;
    [self changeActiveTo:sender];
}

- (IBAction)five:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 300;
    [self changeActiveTo:sender];
}

- (IBAction)noTime:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 0;
    [self changeActiveTo:sender];
}

- (void)changeActiveTo:(NSMenuItem *)newItem
{
    [newItem setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = newItem;
}

- (IBAction)screenStateMenuItem:(NSMenuItem *)sender
{
    if ([sender state]) {
        [self.screenStateMenuItem setState:NSOffState];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSettingsScreenState];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.idleManager screenStateIdle:NO];
    } else {
        [self.screenStateMenuItem setState:NSOnState];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSettingsScreenState];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.idleManager screenStateIdle:YES];
    }
}

@end
