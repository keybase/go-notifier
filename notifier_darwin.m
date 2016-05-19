// Copyright 2016 Keybase, Inc. All rights reserved. Use of
// this source code is governed by the included BSD license.

// Modified from https://github.com/julienXX/terminal-notifier
// Modified from https://github.com/vjeantet/alerter

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
@property NSTimeInterval timeout;
@property (retain) NSString *uuid;
@end

CFStringRef deliverNotification(CFStringRef titleRef, CFStringRef subtitleRef, CFStringRef messageRef, CFStringRef appIconURLStringRef,
  CFArrayRef actionsRef, CFStringRef bundleIDRef, CFStringRef groupIDRef, NSTimeInterval timeout, bool debug) {

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
  if ([actions count] == 1) {
    [userNotification setValue:@YES forKey:@"_showsButtons"];
    userNotification.actionButtonTitle = [actions objectAtIndex:0];
  } else if ([actions count] == 2) {
    [userNotification setValue:@YES forKey:@"_showsButtons"];
    userNotification.otherButtonTitle = [actions objectAtIndex:0];
    userNotification.actionButtonTitle = [actions objectAtIndex:1];
  } else if ([actions count] >= 3) {
    userNotification.otherButtonTitle = [actions objectAtIndex:0];
    NSArray *alternateActions = [actions subarrayWithRange:NSMakeRange(1, [actions count] - 1)];
    [userNotification setValue:@YES forKey:@"_showsButtons"];
    [userNotification setValue:@YES forKey:@"_alwaysShowAlternateActionMenu"];
    [userNotification setValue:alternateActions forKey:@"_alternateActionButtonTitles"];
  }

  NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
  if (debug) NSLog(@"Deliver: %@", userNotification);
  NotificationDelegate *delegate = [[NotificationDelegate alloc] init];
  delegate.timeout = timeout;
  delegate.uuid = uuid;
  userNotificationCenter.delegate = delegate;
  [userNotificationCenter deliverNotification:userNotification];

  [[NSRunLoop mainRunLoop] run];

  return nil;
}

@implementation NotificationDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification {
  return YES;
}

- (void)remove:(NSUserNotification *)userNotification center:(NSUserNotificationCenter *)center fromActivation:(BOOL)fromActivation timedOut:(BOOL)timedOut {
  dispatch_async(dispatch_get_main_queue(), ^{
      [center removeDeliveredNotification:userNotification];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!fromActivation && !timedOut) {
          [self writeResponse:@{@"action": userNotification.otherButtonTitle, @"type": @"action"}];
        }
        fflush(stdout);
        fflush(stderr);
        exit(0);
      });
    });
}

- (void)writeResponse:(NSDictionary *)dict {
  NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
  if (data) {
    [[NSFileHandle fileHandleWithStandardOutput] writeData:data];
    fflush(stdout);
  }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)userNotification {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSDate *start = [NSDate date];
    BOOL timedOut = YES;
    while (-[start timeIntervalSinceNow] < self.timeout) {
      bool found = NO;
      for (NSUserNotification *deliveredNotification in [[NSUserNotificationCenter defaultUserNotificationCenter] deliveredNotifications]) {
        if ([deliveredNotification.userInfo[@"uuid"] isEqual:self.uuid]) {
          [NSThread sleepForTimeInterval:0.5];
          found = YES;
          break;
        }
      }
      if (!found) {
        timedOut = NO;
        break;
      }
    }
    [self remove:userNotification center:center fromActivation:NO timedOut:timedOut];
  });
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)userNotification {
  // There is no easy way to determine if close button was clicked
  // https://stackoverflow.com/questions/21110714/mac-os-x-nsusernotificationcenter-notification-get-dismiss-event-callback
  switch (userNotification.activationType) {
    case NSUserNotificationActivationTypeAdditionalActionClicked:
    case NSUserNotificationActivationTypeActionButtonClicked: {
      NSString *action = nil;
      if ([[(NSObject*)userNotification valueForKey:@"_alternateActionButtonTitles"] count] > 1) {
        NSNumber *alternateActionIndex = [(NSObject*)userNotification valueForKey:@"_alternateActionIndex"];
        int actionIndex = [alternateActionIndex intValue];
        action = [(NSObject*)userNotification valueForKey:@"_alternateActionButtonTitles"][actionIndex];
      } else {
        action = userNotification.actionButtonTitle;
      }
      [self writeResponse:@{@"action": action, @"type": @"action"}];
      break;
    }
    case NSUserNotificationActivationTypeContentsClicked:
      [self writeResponse:@{@"type": @"clicked"}];
      break;
    case NSUserNotificationActivationTypeReplied:
      break;
    case NSUserNotificationActivationTypeNone:
      break;
  }
  [self remove:userNotification center:center fromActivation:YES timedOut:NO];
}

@end
