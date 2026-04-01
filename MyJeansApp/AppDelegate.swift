import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("FCM: Notification permission error: \(error.localizedDescription)")
            }
            print("FCM: Notification permission granted: \(granted)")
        }
        application.registerForRemoteNotifications()

        // Subscribe to the same topic as Android
        Messaging.messaging().subscribe(toTopic: "all_users") { error in
            if let error = error {
                print("FCM: Failed to subscribe to all_users: \(error.localizedDescription)")
            } else {
                print("FCM: Successfully subscribed to all_users topic")
            }
        }

        // Handle notification tap when app was terminated
        if let userInfo = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotificationData(userInfo)
        }

        // Set up the window and root view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = ViewController()
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: - Remote Notification Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("FCM: Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM: Token refreshed: \(fcmToken ?? "nil")")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Called when notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    // Called when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationData(userInfo)
        completionHandler()
    }

    // MARK: - Notification URL Handling

    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        if let urlString = userInfo["url"] as? String, !urlString.isEmpty {
            // Post notification so ViewController can handle the URL
            NotificationCenter.default.post(
                name: NSNotification.Name("PushNotificationURL"),
                object: nil,
                userInfo: ["url": urlString]
            )
            // Also store it for when ViewController hasn't loaded yet
            UserDefaults.standard.set(urlString, forKey: "pendingNotificationURL")
        }
    }
}
