//
//  IdleManager.m
//  idleSound
//
//  Created by Christopher Loessl on 10/13/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

// Used AdiumIdleManager as basis for this class
// https://hg.adium.im/adium/file/8f48d8e917b5/Source/AdiumIdleManager.m

#import "IdleManager.h"
#import "Notifications.h"
#import "common.h"

#define MACHINE_IDLE_THRESHOLD          1800    // 1800 seconds of inactivity is considered idle
#if DEBUG
#define MACHINE_ACTIVE_POLL_INTERVAL       3    // Poll every 3 seconds when the user is active DEBUG MODE
#else
#define MACHINE_ACTIVE_POLL_INTERVAL      30    // Poll every 30 seconds when the user is active
#endif
#define MACHINE_IDLE_POLL_INTERVAL         1    // Poll every second when the user is idle

@interface IdleManager ()
// private properties
@property (assign, nonatomic) BOOL machineIsIdle;
@property (assign, nonatomic) CFTimeInterval lastSeenIdle;
@property (strong, nonatomic) NSTimer *idleTimer;
@property (assign, nonatomic) BOOL screenStateIdle;
@end

/*!
 * @class IdleManager
 * @brief Core class to manage sending notifications when the system is idle or no longer idle
 *
 * Posts AIMachineIsIdleNotification to notification center when the machine becomes idle.
 * Posts AIMachineIsActiveNotification when the machine is no longer idle
 * Posts AIMachineIdleUpdateNotification periodically while idle with an NSDictionary userInfo
 *      containing an NSNumber double value @"Duration" (a CFTimeInterval) and an NSDate @"idleSince".
 */
@implementation IdleManager

/*!
 * @brief Initialise
 */
- (id)init {
    if (self = [super init]) {
        self.screenStateIdle = YES;
        self.machineIdleThreshold = MACHINE_IDLE_THRESHOLD;
    }
    
    return self;
}

/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle. The machine is idle when there are no input
 * events from the user (such as mouse movement or keyboard input) or when the screen saver is active.
 * In addition to this method, the status controller sends out notifications when the machine becomes idle,
 * stays idle, and returns to an active state.
 */
- (CFTimeInterval)currentMachineIdle
{
    CFTimeInterval smallestIdleTime;
    CFTimeInterval tmp;
    
    smallestIdleTime = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventKeyDown);
    tmp = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventMouseMoved);
    if (tmp < smallestIdleTime) {
        smallestIdleTime = tmp;
    }
    tmp = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGEventFlagsChanged);
    if (tmp < smallestIdleTime) {
        smallestIdleTime = tmp;
    }
    
    return smallestIdleTime;
}

/*!
 * @brief Timer that checks for machine idle
 *
 * This timer periodically checks the machine for inactivity.  When the machine has been inactive for at least
 * machineIdleThreshold seconds, a notification is broadcast.
 *
 * When the machine is active, this timer is called infrequently.  It's not important to notice that the user went
 * idle immediately, so we relax our CPU usage while waiting for an idle state to begin.
 *
 * When the machine is idle, the timer is called frequently.  It's important to notice immediately when the user
 * returns.
 */
- (void)idleCheckTimer:(NSTimer *)inTimer {
    CFTimeInterval currentIdle = [self currentMachineIdle];
    
    // don't print to much debugging information
    if (currentIdle < 300 || (int)currentIdle % 600 == 0) {
        DLog(@"Current idle time  : %f", currentIdle);
        DLog(@"Last Seen idle time: %f", self.lastSeenIdle);
    }
    
    if (self.machineIsIdle) {
        // If the user has some idle time saved and then looks screen
        // then the oldIdle time is > newIdle time
        // which leads to "user came back"
        // so we set lastSeenIdle to 0 when the screen gets locked
        if (currentIdle < self.lastSeenIdle) {
            // User came back
            self.machineIsIdle = NO;
        } else {
            // User still idle
            // Periodically broadcast a 'MachineIdleUpdate' notification
            [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIdleUpdateNotification
                                                                object:nil
                                                              userInfo:@{kIdleFor : @(currentIdle),
                                                                         kIdleSince : [NSDate dateWithTimeIntervalSinceNow:-currentIdle]}];
        }
    } else {
        // User went idle
        // If machine inactivity is over the threshold, the user has gone idle.
        if (currentIdle > self.machineIdleThreshold) {
            self.machineIsIdle = YES;
        }
    }
    
    self.lastSeenIdle = currentIdle;
}

/*!
 * @brief Sets the machine as idle or not
 *
 * This internal method updates the frequency of our idle timer depending on whether the machine is considered
 * idle or not.  It also posts the AIMachineIsIdleNotification and AIMachineIsActiveNotification notifications
 * based on the passed idle state
 */
- (void)setMachineIsIdle:(BOOL)inIdle
{
    DLog(inIdle ? @"setMachineIsIdle: Yes" : @"setMachineIsIdle: No");
    
    if ( (_machineIsIdle == inIdle) && (self.idleTimer) ){
        // we are already in the new state
        // this happens e.g. the user locks the screen -> userIdle
        // and then x minutes later this get's called again -> 2nd userIdle
        // so we return and do nothing else
        //
        // Otherwise the problem is, that the "old" state is not actually the old state
        // e.g
        // we are active with sound, then we lock the screen
        // we save "sound on" as old state, then 30min later the user becomes inactive
        // we run the same function again and since we are already "sound off"
        // we save "sound off" als old state and when we become active again
        // we don't restore the sound.
        // hence, don't do it twice.
        DLog(@"Reinvocation of the same state. Doing nothing. return.");
        return;
    }
    
    _machineIsIdle = inIdle;
    
    //Post the appropriate idle or active notification
    if (_machineIsIdle) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIsIdleNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIsActiveNotification object:nil];
    }
    
    // Update our timer interval for either idle or active polling
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    
    // disable idleTimer but still have ScreenStates
    if (self.machineIdleThreshold == 0) return;
    
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:(_machineIsIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL)
                                                      target:self
                                                    selector:@selector(idleCheckTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)disable
{
    [self.idleTimer invalidate];
    if (self.screenStateIdle) {
        [self stopMonitoringScreenChanges];
    }
}

- (void)enable
{
    if (self.screenStateIdle) {
        [self monitorScreenChanges];
    }
    self.machineIsIdle = NO;
}

- (void)setMachineIdleThreshold:(NSInteger)machineIdleThreshold
{
    _machineIdleThreshold = machineIdleThreshold;
    
    [self enable];
}

#pragma mark - Notifications and Observer

/**
 *  @brief Called when the screen state changes
 *
 *  @param notification the notification sent
 *
 *  Gets called whenever the screen saver starts/stops or the
 *  screen lock starts/stops. We set ourself accordingly.
 */
- (void)screenStateDidChange:(NSNotification *)notification {
    NSString *notificationName = [notification name];
    
    DLog(@"screnStateDidChange: %@", notificationName);
    
    if ([notificationName isEqualToString:AIScreensaverDidStartNotification]) {
        self.machineIsIdle = YES;
    } else if ([notificationName isEqualToString:AIScreensaverDidStopNotification]) {
        self.machineIsIdle = NO;
    } else if ([notificationName isEqualToString:AIScreenLockDidStartNotification]) {
        self.machineIsIdle = YES;
    } else if ([notificationName isEqualToString:AIScreenLockDidStopNotification]) {
        self.machineIsIdle = NO;
    }
    
    self.lastSeenIdle = 0.0;
}

// private
- (void)monitorScreenChanges {
    // remove all first, so we won't listen double on notifications
    [self stopMonitoringScreenChanges];
    
    // Register our notifications
    NSNotificationCenter *notificationCenter;
    
    // Screensaver events are _distributed_ notification events
    notificationCenter = [NSDistributedNotificationCenter defaultCenter];
    
    DLog(@"Register on screen state changes in [NSDistributedNotificationCenter defaultCenter]");
    
    [notificationCenter addObserver:self
                           selector:@selector(screenStateDidChange:)
                               name:AIScreensaverDidStartNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(screenStateDidChange:)
                               name:AIScreensaverDidStopNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(screenStateDidChange:)
                               name:AIScreenLockDidStartNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(screenStateDidChange:)
                               name:AIScreenLockDidStopNotification
                             object:nil];

//#ifdef DEBUG
//    // observe ALL notifications
//    [notificationCenter addObserver:self
//                           selector:@selector(observerMethod:)
//                               name:nil
//                             object:nil];
//#endif
}

// private
- (void)stopMonitoringScreenChanges {
    DLog(@"Deregister everything in [NSDistributedNotificationCenter defaultCenter]");
    // Screensaver events are _distributed_ notification events
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)screenStateIdle:(BOOL)state
{
    if (state) {
        self.screenStateIdle = YES;
        [self monitorScreenChanges];
    } else {
        self.screenStateIdle = NO;
        [self stopMonitoringScreenChanges];
    }
}

#pragma mark - dealloc

-(void) dealloc {
    [self stopMonitoringScreenChanges];
}

#pragma mark - DEBUG

//#ifdef DEBUG
//- (void)observerMethod:(NSNotification *)notification
//{
//    NSLog(@"%@",[notification name]);
//}
//#endif

@end
