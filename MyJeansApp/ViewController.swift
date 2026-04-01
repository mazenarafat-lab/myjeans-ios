import UIKit
import WebKit

class ViewController: UIViewController {

    private static let mainURL = "https://myjeans-sy.com/"

    private var webView: WKWebView!
    private var offlineView: UIView!
    private var loadingView: UIView!
    private var activityIndicator: UIActivityIndicatorView!
    private var refreshControl: UIRefreshControl!
    private var isWebViewInitialized = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupWebView()
        setupLoadingView()
        setupOfflineView()
        setupRefreshControl()

        // Listen for push notification URLs
        NotificationCenter.default.addObserver(
            self, selector: #selector(handlePushNotificationURL(_:)),
            name: NSNotification.Name("PushNotificationURL"), object: nil
        )

        // Check for pending notification URL (from cold start)
        if let pendingURL = UserDefaults.standard.string(forKey: "pendingNotificationURL") {
            UserDefaults.standard.removeObject(forKey: "pendingNotificationURL")
            loadURL(pendingURL)
        } else {
            loadMainURL()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        view.addSubview(webView)
    }

    private func setupLoadingView() {
        loadingView = UIView(frame: view.bounds)
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingView.backgroundColor = .white

        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .systemBlue
        activityIndicator.center = loadingView.center
        activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityIndicator.startAnimating()
        loadingView.addSubview(activityIndicator)

        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .systemBlue
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.sizeToFit()
        label.center = CGPoint(x: loadingView.center.x, y: loadingView.center.y + 40)
        label.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        loadingView.addSubview(label)

        view.addSubview(loadingView)
    }

    private func setupOfflineView() {
        offlineView = UIView(frame: view.bounds)
        offlineView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        offlineView.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
        offlineView.isHidden = true

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = "📡"
        iconLabel.font = UIFont.systemFont(ofSize: 60)

        let titleLabel = UILabel()
        titleLabel.text = "No Internet Connection"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .darkGray

        let messageLabel = UILabel()
        messageLabel.text = "Please check your connection and try again."
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = .gray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        retryButton.addTarget(self, action: #selector(onRetryTapped), for: .touchUpInside)

        stackView.addArrangedSubview(iconLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(retryButton)

        offlineView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: offlineView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: offlineView.centerYAnchor),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])

        view.addSubview(offlineView)
    }

    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }

    // MARK: - Navigation

    private func loadMainURL() {
        if isNetworkAvailable() {
            if let url = URL(string: ViewController.mainURL) {
                webView.load(URLRequest(url: url))
            }
        } else {
            showOfflinePage()
        }
    }

    private func loadURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
            showWebView()
        }
    }

    // MARK: - State Management

    private func showWebView() {
        webView.isHidden = false
        offlineView.isHidden = true
        loadingView.isHidden = true
    }

    private func showOfflinePage() {
        webView.isHidden = true
        offlineView.isHidden = false
        loadingView.isHidden = true
    }

    private func showLoadingState() {
        webView.isHidden = true
        offlineView.isHidden = true
        loadingView.isHidden = false
    }

    // MARK: - Network

    private func isNetworkAvailable() -> Bool {
        guard let url = URL(string: "https://www.apple.com") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        // Simple reachability check using host resolution
        let host = "myjeans-sy.com"
        return true // WKWebView will handle load errors via delegate
    }

    // MARK: - Actions

    @objc private func onRetryTapped() {
        if isNetworkAvailable() {
            showLoadingState()
            loadMainURL()
        }
    }

    @objc private func onPullToRefresh() {
        if isNetworkAvailable() {
            webView.reload()
        } else {
            refreshControl.endRefreshing()
            showOfflinePage()
        }
    }

    @objc private func handlePushNotificationURL(_ notification: Notification) {
        if let urlString = notification.userInfo?["url"] as? String {
            loadURL(urlString)
        }
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !isWebViewInitialized {
            showLoadingState()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isWebViewInitialized = true
        showWebView()
        refreshControl.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        showOfflinePage()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        showOfflinePage()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow all navigation within the WebView
        decisionHandler(.allow)
    }
}
