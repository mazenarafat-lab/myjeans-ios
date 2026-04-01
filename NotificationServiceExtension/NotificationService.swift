import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Check for image URL in the data payload
        let imageURLString = bestAttemptContent.userInfo["image"] as? String
            ?? bestAttemptContent.userInfo["fcm_options"] as? [String: Any]
                .flatMap { $0["image"] as? String }

        guard let urlString = imageURLString, !urlString.isEmpty,
              let imageURL = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        // Download the image and attach it to the notification
        downloadImage(from: imageURL) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Deliver the best attempt content before time expires
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { downloadedURL, response, error in
            guard let downloadedURL = downloadedURL, error == nil else {
                print("FCM: Failed to download notification image: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }

            // Move to a temporary location with proper file extension
            let fileExtension = self.fileExtension(from: response, url: url)
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString + fileExtension)

            do {
                try FileManager.default.moveItem(at: downloadedURL, to: tmpURL)
                let attachment = try UNNotificationAttachment(identifier: "image", url: tmpURL, options: nil)
                completion(attachment)
            } catch {
                print("FCM: Failed to create notification attachment: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }

    private func fileExtension(from response: URLResponse?, url: URL) -> String {
        if let mimeType = response?.mimeType {
            switch mimeType {
            case "image/jpeg": return ".jpg"
            case "image/png": return ".png"
            case "image/gif": return ".gif"
            case "image/webp": return ".webp"
            default: break
            }
        }

        let pathExtension = url.pathExtension.lowercased()
        if !pathExtension.isEmpty {
            return "." + pathExtension
        }

        return ".jpg"
    }
}
