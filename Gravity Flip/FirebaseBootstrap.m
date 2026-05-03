// FirebaseBootstrap.m
//
// Initializes Firebase at app launch without modifying Godot's AppDelegate
// (which lives inside libgodot.a). The +load class method runs once when
// the Objective-C runtime loads this binary; we register an observer for
// UIApplicationDidFinishLaunchingNotification and configure FirebaseApp
// from there. Configuring before any FirebaseAnalytics.logEvent call is
// what matters — the post-launch notification fires synchronously after
// AppDelegate's didFinishLaunchingWithOptions returns, so we're safely
// in place before the game starts logging.
//
// FirebaseAnalyticsBridge then takes over for forwarding GDScript events.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@import FirebaseCore;

@interface GFFirebaseBootstrap : NSObject
@end

@implementation GFFirebaseBootstrap

+ (void)load {
    // Use a non-nil queue so the block runs on the main queue regardless
    // of who posts the notification.
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidFinishLaunchingNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification * _Nonnull note) {
        if ([FIRApp defaultApp] == nil) {
#if DEBUG
            // Force Firebase Analytics DebugView on for Debug builds.
            // Equivalent to launching with -FIRDebugEnabled, but works
            // without scheme args (devicectl can't pass launch args).
            // Production (Release) builds skip this entirely.
            [[NSUserDefaults standardUserDefaults]
                setBool:YES forKey:@"/google/measurement/debug_mode"];
            NSLog(@"[FirebaseBootstrap] DEBUG build: Analytics DebugView enabled");
#endif
            [FIRApp configure];
            NSLog(@"[FirebaseBootstrap] FirebaseApp.configure() done");
        }
        // Kick off the GDScript event-forwarder. The Swift class is
        // exposed to ObjC via @objc and lives in the same module.
        Class bridge = NSClassFromString(@"Gravity_Flip.AnalyticsBridge");
        if (bridge) {
            [bridge performSelector:@selector(start)];
        } else {
            NSLog(@"[FirebaseBootstrap] AnalyticsBridge class not found");
        }
    }];
}

@end
