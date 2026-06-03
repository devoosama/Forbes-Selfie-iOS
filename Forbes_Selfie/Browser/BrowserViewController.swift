import UIKit
import WebKit

// MARK: - Message names from JS
enum JSMessageName: String, CaseIterable {
    case livenessResult     = "livenessResult"
    case sessionUpdate      = "sessionUpdate"
    case log                = "log"
    case close              = "close"
}

// MARK: - BrowserViewController
class BrowserViewController: UIViewController {

    // MARK: - Properties
    var startURL: URL
    var sessionCode: String
    var onComplete: ((String) -> Void)?
    var onClose: (() -> Void)?

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var progressObserver: NSKeyValueObservation?

    // MARK: - Init
    init(url: URL, code: String) {
        self.startURL = url
        self.sessionCode = code
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupProgressView()
        setupNavBar()
        loadURL()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressObserver?.invalidate()
    }

    // MARK: - Setup WebView
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Register message handlers
        let contentController = config.userContentController
        for name in JSMessageName.allCases {
            contentController.add(WeakMessageHandler(delegate: self), name: name.rawValue)
        }

        // Inject scripts
        injectScripts(into: contentController)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = UIColor(red: 7/255, green: 9/255, blue: 26/255, alpha: 1)
        webView.isOpaque = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = UIColor(red: 14/255, green: 165/255, blue: 233/255, alpha: 1)
        progressView.trackTintColor = .clear
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
        progressObserver = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            DispatchQueue.main.async {
                self?.progressView.progress = Float(wv.estimatedProgress)
                self?.progressView.isHidden = wv.estimatedProgress >= 1.0
            }
        }
    }

    private func setupNavBar() {
        view.backgroundColor = UIColor(red: 7/255, green: 9/255, blue: 26/255, alpha: 1)
        title = "FacePass"
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = UIColor(red: 14/255, green: 165/255, blue: 233/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .bold)
        ]
        navigationController?.navigationBar.barTintColor = UIColor(red: 7/255, green: 9/255, blue: 26/255, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
    }

    private func loadURL() {
        // Fetch OZ SDK via Swift URLSession (no WebKit cross-origin restrictions),
        // then inject it inline. baseURL = blsspainmorocco.net so window.location.origin
        // matches the authorized domain.
        let ozURL = startURL
        let baseURL = URL(string: "https://www.blsspainmorocco.net/MAR/appointment/livenessrequest")!

        URLSession.shared.dataTask(with: ozURL) { [weak self] data, _, error in
            guard let self = self else { return }

            let sdkJS: String
            if let data = data, let js = String(data: data, encoding: .utf8), !js.isEmpty {
                sdkJS = js
            } else {
                // Fallback: load as direct request
                DispatchQueue.main.async {
                    self.webView.load(URLRequest(url: ozURL))
                }
                return
            }

            let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
            <style>*{margin:0;padding:0}html,body{width:100%;height:100%;background:#07091A;overflow:hidden}</style>
            </head>
            <body>
            <script>
            \(sdkJS)
            </script>
            </body>
            </html>
            """
            DispatchQueue.main.async {
                self.webView.loadHTMLString(html, baseURL: baseURL)
            }
        }.resume()
    }

    // MARK: - Script Injection
    private func injectScripts(into contentController: WKUserContentController) {
        // 1. Inject content.js at document start
        if let js = loadBundleScript(name: "content") {
            let userScript = WKUserScript(
                source: js,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            contentController.addUserScript(userScript)
        }

        // 2. Inject liveness.js at document end (after DOM ready)
        if let js = loadBundleScript(name: "liveness") {
            let userScript = WKUserScript(
                source: js,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
            contentController.addUserScript(userScript)
        }
    }

    private func loadBundleScript(name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js") else {
            print("[Forbes] ⚠️ Script not found: \(name).js")
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onClose?()
        }
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Inject session code into page context
        let js = "window.__FORBES_CODE__ = '\(sessionCode)';"
        webView.evaluateJavaScript(js)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate
extension BrowserViewController: WKUIDelegate {
    // Allow camera access
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.grant)
    }
}

// MARK: - WKScriptMessageHandler
extension BrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                didReceive message: WKScriptMessage) {
        guard let name = JSMessageName(rawValue: message.name) else { return }

        switch name {
        case .livenessResult:
            if let body = message.body as? [String: Any],
               let livenessId = body["liveness_id"] as? String {
                print("[Forbes] ✅ Liveness result: \(livenessId)")
                onComplete?(livenessId)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.dismiss(animated: true)
                }
            }

        case .sessionUpdate:
            if let body = message.body as? [String: Any],
               let status = body["status"] as? String {
                print("[Forbes] 🔄 Session update: \(status)")
            }

        case .log:
            if let msg = message.body as? String {
                print("[Forbes] 📋 JS: \(msg)")
            }

        case .close:
            closeTapped()
        }
    }
}

// MARK: - Weak Message Handler (avoid retain cycle)
private class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ ctrl: WKUserContentController, didReceive msg: WKScriptMessage) {
        delegate?.userContentController(ctrl, didReceive: msg)
    }
}
