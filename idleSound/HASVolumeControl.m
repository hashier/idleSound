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
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioDevicePropertyMute;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    propertySize = sizeof(Float32);
    UInt32 mute;

    status = AudioHardwareServiceGetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, &propertySize, &mute);
    
    if (status) {
        NSLog(@"Can't get mute information for dev: 0x%0x", outputDeviceID);
    }
    
    return mute;
}

+ (void)unMuted {
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    propertyAOPA.mSelector = kAudioDevicePropertyMute;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    propertySize = sizeof(Float32);
    UInt32 mute = 0;
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
        return;
    }
    
    Boolean canSetMute = NO;
    
    status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetMute);
    
    if (status || !canSetMute) {
        NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
        return;
    }
    
    status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

// getting system volume
+ (float)volume {
    Float32 outputVolume;
    
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return 0.0;
    }
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"No volume returned for device 0x%0x", outputDeviceID);
        return 0.0;
    }
    
    propertySize = sizeof(Float32);
    
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
    AudioDeviceID outputDeviceID = kAudioObjectUnknown;
    
    // get output device device
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    
    if (!AudioHardwareServiceHasProperty(kAudioObjectSystemObject, &propertyAOPA)) {
        NSLog(@"Cannot find default output device!");
        return outputDeviceID;
    }
    
    propertySize = sizeof(AudioDeviceID);
    
    status = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject, &propertyAOPA, 0, NULL, &propertySize, &outputDeviceID);
    
    if(status) {
        NSLog(@"Cannot find default output device!");
    }
    return outputDeviceID;
}

+ (void)setMute {
    [[self class] setVolume:0.0];
}

// setting system volume - mutes if under threshhold
+ (void)setVolume:(Float32)newVolume {
    if (newVolume < 0.0 || newVolume > 1.0) {
        NSLog(@"Requested volume out of range (%.2f)", newVolume);
        return;
    }
    
    // get output device device
    UInt32 propertySize = 0;
    OSStatus status = noErr;
    AudioObjectPropertyAddress propertyAOPA;
    propertyAOPA.mElement = kAudioObjectPropertyElementMaster;
    propertyAOPA.mScope = kAudioDevicePropertyScopeOutput;
    
    if (newVolume < 0.001) {
        NSLog(@"Requested mute");
        propertyAOPA.mSelector = kAudioDevicePropertyMute;
    } else {
        NSLog(@"Requested volume %.2f", newVolume);
        propertyAOPA.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
    }
    
    AudioDeviceID outputDeviceID = [[self class] defaultOutputDeviceID];
    
    if (outputDeviceID == kAudioObjectUnknown) {
        NSLog(@"Unknown device");
        return;
    }
    
    if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    Boolean canSetVolume = NO;
    
    status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetVolume);
    
    if (status || canSetVolume == NO) {
        NSLog(@"Device 0x%0x does not support volume control", outputDeviceID);
        return;
    }
    
    if (propertyAOPA.mSelector == kAudioDevicePropertyMute) {
        propertySize = sizeof(UInt32);
        UInt32 mute = 1;
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    } else {
        propertySize = sizeof(Float32);
        
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &newVolume);
        
        if (status) {
            NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
        }
        
        // make sure we're not muted
        propertyAOPA.mSelector = kAudioDevicePropertyMute;
        propertySize = sizeof(UInt32);
        UInt32 mute = 0;
        
        if (!AudioHardwareServiceHasProperty(outputDeviceID, &propertyAOPA)) {
            NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
            return;
        }
        
        Boolean canSetMute = NO;
        
        status = AudioHardwareServiceIsPropertySettable(outputDeviceID, &propertyAOPA, &canSetMute);
        
        if (status || !canSetMute) {
            NSLog(@"Device 0x%0x does not support muting", outputDeviceID);
            return;
        }
        
        status = AudioHardwareServiceSetPropertyData(outputDeviceID, &propertyAOPA, 0, NULL, propertySize, &mute);
    }
    
    if (status) {
        NSLog(@"Unable to set volume for device 0x%0x", outputDeviceID);
    }
}

/*
#pragma mark - Old API, don't USE
// It's just here if I need to compile for older OS X someday

- (float)getVolume {
    float b_vol;
    OSStatus err;
    AudioDeviceID device;
    UInt32 size;
    UInt32 channels[2];
    float volume[2];
    
    // get device
    size = sizeof device;
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    if(err!=noErr) {
        NSLog(@"audio-volume error get device");
        return 0.0;
    }
    
    // try set master volume (channel 0)
    size = sizeof b_vol;
    err = AudioDeviceGetProperty(device, 0, 0, kAudioDevicePropertyVolumeScalar, &size, &b_vol);
    //kAudioDevicePropertyVolumeScalarToDecibels
    if(noErr==err)
        return b_vol;
    
    // otherwise, try seperate channels
    // get channel numbers
    size = sizeof(channels);
    err = AudioDeviceGetProperty(device, 0, 0,kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
    if(err!=noErr)
        NSLog(@"error getting channel-numbers");
    
    size = sizeof(float);
    err = AudioDeviceGetProperty(device, channels[0], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[0]);
    if(noErr!=err)
        NSLog(@"error getting volume of channel %d",channels[0]);
    err = AudioDeviceGetProperty(device, channels[1], 0, kAudioDevicePropertyVolumeScalar, &size, &volume[1]);
    if(noErr!=err)
        NSLog(@"error getting volume of channel %d",channels[1]);
    
    b_vol = (volume[0]+volume[1])/2.00;
    
    return b_vol;
}

- (void)setVolume:(float)involume { OSStatus err; AudioDeviceID device; UInt32 size; Boolean canset = false; UInt32 channels[2]; //float volume[2];
    
    // get default device
    size = sizeof device;
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &size, &device);
    if(err!=noErr) {
        NSLog(@"audio-volume error get device");
        return;
    }
    
    // try set master-channel (0) volume
    size = sizeof canset;
    err = AudioDeviceGetPropertyInfo(device, 0, false, kAudioDevicePropertyVolumeScalar, &size, &canset);
    if(err==noErr && canset==true) {
        size = sizeof involume;
        err = AudioDeviceSetProperty(device, NULL, 0, false, kAudioDevicePropertyVolumeScalar, size, &involume);
        return;
    }
    
    // else, try seperate channes
    // get channels
    size = sizeof(channels);
    err = AudioDeviceGetProperty(device, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &size,&channels);
    if(err!=noErr) {
        NSLog(@"error getting channel-numbers");
        return;
    }
    
    // set volume
    size = sizeof(float);
    err = AudioDeviceSetProperty(device, 0, channels[0], false, kAudioDevicePropertyVolumeScalar, size, &involume);
    if(noErr!=err)
        NSLog(@"error setting volume of channel %d",channels[0]);
    err = AudioDeviceSetProperty(device, 0, channels[1], false, kAudioDevicePropertyVolumeScalar, size, &involume);
    if(noErr!=err)
        NSLog(@"error setting volume of channel %d",channels[1]);
}
*/

@end
