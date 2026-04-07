import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Initialize Firebase
        FirebaseApp.configure()

        // 2. Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // 3. Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("FCM: Notification permission error: \(error.localizedDescription)")
            }
            print("FCM: Notification permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()

        // 4. Subscribe to the same topic as Android
        Messaging.messaging().subscribe(toTopic: "all_users") { error in
            if let error = error {
                print("FCM: Failed to subscribe to all_users: \(error.localizedDescription)")
            } else {
                print("FCM: Successfully subscribed to all_users topic")
            }
        }

        // 5. Handle notification tap when app was terminated
        if let userInfo = launchOptions?[.remoteNotification] as? [String: Any] {
            handleNotificationData(userInfo)
        }

        // 6. Set up the window and root view controller
        // Note: Ensure ViewController.swift exists in your project
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
        guard let token = fcmToken else {
            print("FCM: Token is nil")
            return
        }
        
        print("FCM: Token refreshed: \(token)")

        // --- WINDOWS USER HELPER: SEND TOKEN TO WEBHOOK ---
        let webhookString = "https://webhook.site/01b64d1f-3dc2-4705-aa31-56bcc0ae38a0" 
        if let url = URL(string: webhookString) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = ["fcmToken": token, "platform": "iOS"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { _, _, _ in
                print("FCM: Token sent to Webhook for Windows user.")
            }
            task.resume()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification interaction (tap)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationData(userInfo)
        completionHandler()
    }

    // MARK: - Notification URL Handling

    private func handleNotificationData(_ userInfo: [AnyHashable: Any]) {
        // Look for the "url" key in the Firebase Data payload
        if let urlString = userInfo["url"] as? String, !urlString.isEmpty {
            print("FCM: Found URL in payload: \(urlString)")
            
            // Post notification locally so the ViewController can react
            NotificationCenter.default.post(
                name: NSNotification.Name("PushNotificationURL"),
                object: nil,
                userInfo: ["url": urlString]
            )
            
            // Store it in case the app is still loading
            UserDefaults.standard.set(urlString, forKey: "pendingNotificationURL")
        }
    }
}
