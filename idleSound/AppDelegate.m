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
@property (weak) IBOutlet NSMenuItem *screenStateMenuItem;
@property (weak) IBOutlet NSMenuItem *sixtyMenuItem;
@property (weak) IBOutlet NSMenuItem *thirtyMenuItem;
@property (weak) IBOutlet NSMenuItem *fiftenMenuItem;
@property (weak) IBOutlet NSMenuItem *fiveMenuItem;
@property (weak) IBOutlet NSMenuItem *ignoreMenuItem;

@end

@implementation AppDelegate

#define kSettingsTime @"org.loessl.idleSound.settings.time"
#define kSettingsScreenState @"org.loessl.idleSound.settings.screenState"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DLog(@"Version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
    // enable sudden process termination
    [[NSProcessInfo processInfo] enableSuddenTermination];
    
    self.idleManager = [[IdleManager alloc] init];
    
    [self setupMenuBarItem];
    [self loadSettings];
    [self registerObserver];
    [self language];
}

#pragma mark - Layout

- (void)setupMenuBarItem {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusItemMenu;
    self.statusItem.highlightMode = YES;
}

#pragma mark - Translations

- (void)language {
    self.quit.title = NSLocalizedString(@"Quit", @"Click to quit the app");
    self.statusItem.title = NSLocalizedString(@"S", @"Title of idleSound");
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

#pragma mark - Getter Setter

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)about:(id)sender {
    NSString *appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *versionBuildString = [NSString stringWithFormat:@"Version: %@ (%@)", appVersionString, appBuildString];
    NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"idleSound\n\nidleSound is free and open source software which automatically mutes your Mac after a specified time.\n\nYou can set the idle time after which the Mac should be muted.\nWith the ScreenState setting you can decide whether ScreenSleep and ScreenSaver should mute the Mac as well.", @"\n\nCopyright (C) 2013 Christopher Loessl\n\n", versionBuildString];
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
    [self saveThreshold:3600];
    [self changeActiveTo:sender];
}

- (IBAction)thirty:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 1800;
    [self saveThreshold:1800];
    [self changeActiveTo:sender];
}

- (IBAction)fifteen:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 900;
    [self saveThreshold:900];
    [self changeActiveTo:sender];
}

- (IBAction)five:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 300;
    [self saveThreshold:300];
    [self changeActiveTo:sender];
}

- (IBAction)noTime:(NSMenuItem *)sender {
    self.idleManager.machineIdleThreshold = 0;
    [self saveThreshold:0];
    [self changeActiveTo:sender];
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

#pragma mark Helper

- (void)changeActiveTo:(NSMenuItem *)newItem
{
    [newItem setState:NSOnState];
    [self.activeMenuItem setState:NSOffState];
    self.activeMenuItem = newItem;
}

- (void)saveThreshold:(NSInteger)threshold
{
    [[NSUserDefaults standardUserDefaults] setInteger:threshold forKey:kSettingsTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSettings
{
    NSMenuItem *settingActivate;
    
    // screen state
    BOOL screenStateIdle = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsScreenState];
    [self.idleManager screenStateIdle:screenStateIdle];
    screenStateIdle ? [self.screenStateMenuItem setState:NSOnState] : [self.screenStateMenuItem setState:NSOffState];
    
    // idle time
    NSInteger timeIdle = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingsTime];
    self.idleManager.machineIdleThreshold = timeIdle;
    switch (timeIdle) {
        case 0:
            settingActivate = self.ignoreMenuItem;
            break;
        case 300:
            settingActivate = self.fiveMenuItem;
            break;
        case 900:
            settingActivate = self.fiftenMenuItem;
            break;
        case 1800:
            settingActivate = self.thirtyMenuItem;
            break;
        case 3600:
            settingActivate = self.sixtyMenuItem;
            break;
        default:
            NSLog(@"Error: Case not handled. Setting threshold");
            break;
    }
    [self changeActiveTo:settingActivate];
}

@end
