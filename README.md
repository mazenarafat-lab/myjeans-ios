# MyJeans iOS WebView App

An iOS WebView application that loads https://myjeans-sy.com/ with push notification support. This is the iOS counterpart of the [Android app](https://github.com/mazenarafat-lab/myjeans-app).

## Features

- **WebView**: Loads the MyJeans website using WKWebView
- **Push Notifications**: Firebase Cloud Messaging integration with topic subscription
- **Notification Images**: Rich notifications with image support via Notification Service Extension
- **URL Deep Linking**: Tap a notification to navigate directly to a specific URL
- **Offline Detection**: Shows a friendly offline page with retry button when no internet
- **Pull-to-Refresh**: Swipe down to reload the page
- **Loading Screen**: Displays a loading indicator on first launch

## Prerequisites

1. **Mac with Xcode 15+** (required for iOS development)
2. **Apple Developer Account** (for push notifications)
3. **CocoaPods** installed: `sudo gem install cocoapods`
4. **Firebase Project** (same one used for the Android app)

## Setup Instructions

### Step 1: Clone the Repo

```bash
git clone https://github.com/mazenarafat-lab/myjeans-ios.git
cd myjeans-ios
```

### Step 2: Install Dependencies

```bash
pod install
```

### Step 3: Set Up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Open your existing **myjeans-app-v3** project
3. Click **Add App** > **iOS**
4. Enter bundle ID: `com.myjeans.app`
5. Download `GoogleService-Info.plist`
6. Place it in the `MyJeansApp/` folder

### Step 4: Enable Push Notifications in Xcode

1. Open `MyJeansApp.xcworkspace` in Xcode (use the `.xcworkspace`, not `.xcodeproj`)
2. Select the **MyJeansApp** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability** and add:
   - **Push Notifications**
   - **Background Modes** > check **Remote notifications**
5. Set your **Team** for code signing (both MyJeansApp and NotificationServiceExtension targets)

### Step 5: Upload APNs Key to Firebase

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Create a new **Key** with **Apple Push Notifications service (APNs)** enabled
3. Download the `.p8` file
4. In Firebase Console > Project Settings > Cloud Messaging > iOS app
5. Upload the APNs key (`.p8` file), enter Key ID and Team ID

### Step 6: Build and Run

1. Connect your iPhone or select a simulator
2. Build and run from Xcode (Cmd + R)

## Project Structure

```
myjeans-ios/
├── MyJeansApp/
│   ├── AppDelegate.swift              # App lifecycle, Firebase & push notification setup
│   ├── ViewController.swift           # Main WebView controller with offline/loading states
│   ├── Info.plist                     # App configuration
│   ├── Assets.xcassets/               # App icons and colors
│   └── Base.lproj/
│       └── LaunchScreen.storyboard    # Launch screen
├── NotificationServiceExtension/
│   ├── NotificationService.swift      # Downloads and attaches images to notifications
│   └── Info.plist                     # Extension configuration
├── MyJeansApp.xcodeproj/             # Xcode project
├── Podfile                           # CocoaPods dependencies (Firebase)
└── README.md
```

## WordPress Plugin Compatibility

This iOS app works with the same WordPress push notification plugin used by the Android app. The plugin should send **data-only** FCM messages with the following keys:

```json
{
  "data": {
    "title": "Notification Title",
    "body": "Notification message",
    "url": "https://myjeans-sy.com/target-page",
    "image": "https://example.com/image.jpg"
  }
}
```

The app subscribes to the `all_users` FCM topic, matching the Android app configuration.

## Troubleshooting

- **Notifications not working?** Make sure you uploaded the APNs key to Firebase and enabled Push Notifications capability in Xcode
- **Images not showing in notifications?** Make sure the NotificationServiceExtension target is properly signed and the `mutable-content` flag is set (Firebase handles this automatically for data-only messages)
- **App shows offline page?** Check your internet connection and try the retry button
