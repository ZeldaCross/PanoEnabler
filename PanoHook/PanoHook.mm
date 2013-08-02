#import "../definitions.h"
#import <substrate.h>
#import "IOKitDefines.h"

static NSDictionary *prefDict = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[prefDict release];
	prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
}

static CFTypeRef (*orig_registryEntry)(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options);
CFTypeRef replaced_registryEntry(io_registry_entry_t entry,  CFStringRef key, CFAllocatorRef allocator, IOOptionBits options) {
    CFTypeRef retval = NULL;
    retval = orig_registryEntry(entry, key, allocator, options);
    if (CFEqual(key, CFSTR("camera-panorama")) && Bool(prefDict, @"PanoEnabled", NO)) {
    	const UInt8 enable[8] = {0, 1, 0, 0, 0, 0, 0, 0};
        retval = CFDataCreate(kCFAllocatorDefault, enable, 4);
    }
    else
        retval = orig_registryEntry(entry, key, allocator, options);
    return retval;
}


__attribute__((constructor)) static void PanoHookInit() {
    prefDict = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
    MSHookFunction((void *)IORegistryEntryCreateCFProperty, (void *)replaced_registryEntry, (void **)&orig_registryEntry);
}