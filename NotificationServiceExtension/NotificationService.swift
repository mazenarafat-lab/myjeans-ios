import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Logic: Try to find the image URL in the root or inside fcm_options
        var imageURLString: String? = bestAttemptContent.userInfo["image"] as? String
        
        if imageURLString == nil {
            if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any] {
                imageURLString = fcmOptions["image"] as? String
            }
        }

        // If we found a URL, download it; otherwise, just show the notification text
        guard let urlString = imageURLString, !urlString.isEmpty,
              let imageURL = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        downloadImage(from: imageURL) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { downloadedURL, response, error in
            guard let downloadedURL = downloadedURL, error == nil else {
                completion(nil)
                return
            }

            // Using your MIME type logic to get the right extension
            let fileExtension = self.determineExtension(from: response, url: url)
            let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString + fileExtension)

            do {
                try FileManager.default.moveItem(at: downloadedURL, to: tmpURL)
                let attachment = try UNNotificationAttachment(identifier: "image", url: tmpURL, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    private func determineExtension(from response: URLResponse?, url: URL) -> String {
        if let mimeType = response?.mimeType {
            switch mimeType {
            case "image/jpeg": return ".jpg"
            case "image/png": return ".png"
            case "image/gif": return ".gif"
            case "image/webp": return ".webp"
            default: break
            }
        }
        let pathExt = url.pathExtension.lowercased()
        return pathExt.isEmpty ? ".jpg" : "." + pathExt
    }
}