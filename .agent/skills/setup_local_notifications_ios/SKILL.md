---
name: "setup_local_notifications_ios"
description: "How to correctly setup flutter_local_notifications for iOS in AppDelegate.swift"
---

# Setup Local Notifications (iOS)

To avoid `MissingPluginException` or delegate errors on iOS when using `flutter_local_notifications`:

1.  **Open `ios/Runner/AppDelegate.swift`**
2.  **Import** the module if needed (usually handled by `GeneratedPluginRegistrant` but good to know).
3.  **Update `didFinishLaunchingWithOptions`**:
    *   Set the `UNUserNotificationCenter` delegate.
    *   Register the plugin callback if using background isolation.

```swift
import UIKit
import Flutter
import flutter_local_notifications // Add if needed, usually not required with auto-linking

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // This is required for the plugin to work correctly even in foreground
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```
