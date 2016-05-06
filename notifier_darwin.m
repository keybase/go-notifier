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

CFStringRef deliverNotification(CFStringRef title, CFStringRef subtitle, CFStringRef message, CFStringRef appIconURLString,
  CFStringRef bundleID, CFStringRef groupID,
  CFStringRef actionButtonTitle, CFStringRef otherButtonTitle) {

  if (bundleID) {
    _fakeBundleIdentifier = (NSString *)bundleID;
  }
  installFakeBundleIdentifierHook();

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults:@{@"sender": @"com.apple.Terminal"}];

  NSUserNotification *userNotification = [[NSUserNotification alloc] init];
  userNotification.title = (NSString *)title;
  userNotification.subtitle = (NSString *)subtitle;
  userNotification.informativeText = (NSString *)message;
  NSMutableDictionary *options = [NSMutableDictionary dictionary];
  if (groupID) {
    options[@"groupID"] = (NSString *)groupID;
  }
  NSString *uuid = [[NSUUID UUID] UUIDString];
  options[@"uuid"] = uuid;
  userNotification.userInfo = options;
  if (appIconURLString) {
    NSURL *appIconURL = [NSURL URLWithString:(NSString *)appIconURLString];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:appIconURL];
    if (image) {
      [userNotification setValue:image forKey:@"_identityImage"];
      [userNotification setValue:@(false) forKey:@"_identityImageHasBorder"];
    }
  }

  if (actionButtonTitle) {
    userNotification.actionButtonTitle = (NSString *)actionButtonTitle;
  }
  if (otherButtonTitle) {
    userNotification.otherButtonTitle = (NSString *)otherButtonTitle;
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
