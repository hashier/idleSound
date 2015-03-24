//
//  HASVolumeControl.m
//  idleSound
//
//  Created by Christopher Loessl on 10/13/13.
//  Copyright (c) 2013 Christopher Loessl. All rights reserved.
//

// Visit http://cocoadev.com/SoundVolume for information.
// Most of the code is just copied from there

#import "HASVolumeControl.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation HASVolumeControl

#pragma mark - New API

+ (bool)isMuted {
    OSStatus status = noErr;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
    }
    
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioDevicePropertyMute;
    
    UInt32 mute;
    UInt32 propertySize = sizeof(mute);

    status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &mute);
    
    if (status) {
        NSLog(@"Can't get mute information for dev: 0x%0x", outputDeviceID);
    }
    
    return mute;
}

+ (void)mute {
    [self setMuteStateTo:YES];
}

+ (void)unmute {
    [self setMuteStateTo:NO];
}

+ (void)setMuteStateTo:(BOOL)state {
    OSStatus status = noErr;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return;
    }
    
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioDevicePropertyMute;
    
    UInt32 mute;
    UInt32 propertySize = sizeof(mute);
    
    Boolean canSetMute = NO;
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
        return;
    }
    
    status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetMute);
    
    if (status || !canSetMute) {
        NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
        return;
    }
    
    if (state) {
        mute = 1;
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    } else {
        mute = 0;
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    }
    
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

// getting system volume
+ (Float32)volume {
    OSStatus status = noErr;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return 0.0;
    }
    
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    
    Float32 outputVolume;
    UInt32 propertySize = sizeof(outputVolume);
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &outputVolume);
    
    if (status) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    if (outputVolume < 0.0 || outputVolume > 1.0)
        return 0.0;
    
    return outputVolume;
}

+ (AudioDeviceID)defaultOutputDeviceID {
    OSStatus status = noErr;
    
    AudioDeviceID outputDeviceID = kAudioObjectUnknown;
    
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAOPA.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    
    UInt32 propertySize = sizeof(outputDeviceID);
    
    if (!AudioHardwareServiceHasProperty(kAudioObjectSystemObject, &propertyAOPA)) {
        NSLog(@"Cannot find default output device!");
        return outputDeviceID;
    }
    
    status = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAOPA, 0, NULL, &propertySize, &outputDeviceID);
    
    if(status) {
        NSLog(@"Cannot find default output device!");
    }
    
    return outputDeviceID;
}

+ (void)setVolume:(Float32)newVolume {
    if (newVolume < 0.0 || newVolume > 1.0) {
        NSLog(@"Requested volume out of range (%.2f)", newVolume);
        return;
    }
    
    OSStatus status = noErr;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return;
    }
    
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    
    UInt32 propertySize = sizeof(newVolume);
    
    Boolean canSetVolume = NO;
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetVolume);
    
    if (status || !canSetVolume) {
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &newVolume);
    
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

@end
