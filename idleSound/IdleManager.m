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

#define MACHINE_IDLE_THRESHOLD          1800    // 1800 seconds of inactivity is considered idle
#define MACHINE_ACTIVE_POLL_INTERVAL      30    // Poll every 30 seconds when the user is active
#define MACHINE_IDLE_POLL_INTERVAL         1    // Poll every second when the user is idle

@interface IdleManager ()
// private properties
@property (assign, nonatomic) BOOL machineIsIdle;
@property (assign, nonatomic) CFTimeInterval lastSeenIdle;
@property (strong, nonatomic) NSTimer *idleTimer;
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
 * @brief Initialize
 */
- (id)init {
    if (self = [super init]) {
        self.machineIdleThreshold = MACHINE_IDLE_THRESHOLD;
        self.machineIsIdle = NO;
        
        // Register our notifications
        NSNotificationCenter *notificationCenter;
        
        // Screensaver events are distributed notification events
        notificationCenter = [NSDistributedNotificationCenter defaultCenter];
        
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
        
    }
    
    return self;
}

/*!
 * @brief Returns the current machine idle time
 *
 * Returns the current number of seconds the machine has been idle.  The machine is idle when there are no input
 * events from the user (such as mouse movement or keyboard input) or when the screen saver is active.
 * In addition to this method, the status controller sends out notifications when the machine becomes idle,
 * stays idle, and returns to an active state.
 */
- (CFTimeInterval)currentMachineIdle
{
    return CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateCombinedSessionState, kCGAnyInputEventType);
}

/*!
 * @brief Timer that checkes for machine idle
 *
 * This timer periodically checks the machine for inactivity.  When the machine has been inactive for atleast
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
    
    if (self.machineIsIdle) {
        if (currentIdle < self.lastSeenIdle) {
            // User came back
            self.machineIsIdle = NO;
        } else {
            // User still idle
            // Periodically broadcast a 'MachineIdleUpdate' notification
            [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIdleUpdateNotification
                                                                object:nil
                                                              userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [NSNumber numberWithDouble:currentIdle], kIdleFor,
                                                                        [NSDate dateWithTimeIntervalSinceNow:-currentIdle], kIdleSince,
                                                                        nil]];
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
    _machineIsIdle = inIdle;
    
    //Post the appropriate idle or active notification
    if (_machineIsIdle) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIsIdleNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:AIMachineIsActiveNotification object:nil];
    }
    
    // Update our timer interval for either idle or active polling
    [self.idleTimer invalidate];
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:(_machineIsIdle ? MACHINE_IDLE_POLL_INTERVAL : MACHINE_ACTIVE_POLL_INTERVAL)
                                                      target:self
                                                    selector:@selector(idleCheckTimer:)
                                                    userInfo:nil
                                                     repeats:YES];
}

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
    
    if ([notificationName isEqualToString:AIScreensaverDidStartNotification]) {
        [self setMachineIsIdle:YES];
    } else if ([notificationName isEqualToString:AIScreensaverDidStopNotification]) {
        [self setMachineIsIdle:NO];
    } else if ([notificationName isEqualToString:AIScreenLockDidStartNotification]) {
        [self setMachineIsIdle:YES];
    } else if ([notificationName isEqualToString:AIScreenLockDidStopNotification]) {
        [self setMachineIsIdle:NO];
    }
}

@end
