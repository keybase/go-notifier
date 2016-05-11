// Copyright 2016 Keybase, Inc. All rights reserved. Use of
// this source code is governed by the included BSD license.

// Modified from https://github.com/julienXX/terminal-notifier

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

NSString *_fakeBundleIdentifier = nil;
@implementation NSBundle (FakeBundleIdentifier)
- (NSString *)__bundleIdentifier {
  if (self == [NSBundle mainBundle]) {
    return _fakeBundleIdentifier ? _fakeBundleIdentifier : @"com.apple.Terminal";
  } else {
    return [self __bundleIdentifier];
  }
}
@end

static BOOL installFakeBundleIdentifierHook() {
  Class class = objc_getClass("NSBundle");
  if (class) {
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(bundleIdentifier)), class_getInstanceMethod(class, @selector(__bundleIdentifier)));
    return YES;
  }
  return NO;
}

@interface NotificationDelegate : NSObject <NSUserNotificationCenterDelegate>
@end

CFStringRef deliverNotification(CFStringRef titleRef, CFStringRef subtitleRef, CFStringRef messageRef, CFStringRef appIconURLStringRef,
  CFArrayRef actionsRef, CFStringRef bundleIDRef, CFStringRef groupIDRef) {

  if (bundleIDRef) {
    _fakeBundleIdentifier = (NSString *)bundleIDRef;
  }
  installFakeBundleIdentifierHook();

  NSUserNotification *userNotification = [[NSUserNotification alloc] init];
  userNotification.title = (NSString *)titleRef;
  userNotification.subtitle = (NSString *)subtitleRef;
  userNotification.informativeText = (NSString *)messageRef;
  NSMutableDictionary *options = [NSMutableDictionary dictionary];
  if (groupIDRef) {
    options[@"groupID"] = (NSString *)groupIDRef;
  }
  NSString *uuid = [[NSUUID UUID] UUIDString];
  options[@"uuid"] = uuid;
  userNotification.userInfo = options;
  if (appIconURLStringRef) {
    NSURL *appIconURL = [NSURL URLWithString:(NSString *)appIconURLStringRef];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:appIconURL];
    if (image) {
      [userNotification setValue:image forKey:@"_identityImage"];
      [userNotification setValue:@(false) forKey:@"_identityImageHasBorder"];
    }
  }
  NSArray *actions = (NSArray *)actionsRef;
  if ([actions count] >= 1) {
    userNotification.actionButtonTitle = [actions objectAtIndex:0];
    [userNotification setValue:@YES forKey:@"_showsButtons"];
  }
  if ([actions count] >= 2) {
    userNotification.otherButtonTitle = [actions objectAtIndex:1];
  }

  NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
  //NSLog(@"Deliver: %@", userNotification);
  userNotificationCenter.delegate = [[NotificationDelegate alloc] init];
  [userNotificationCenter scheduleNotification:userNotification];
  [[NSRunLoop mainRunLoop] run];
  return nil;
}

@implementation NotificationDelegate
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification {
  return YES;
}
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)userNotification {
  exit(0);
}
@end
