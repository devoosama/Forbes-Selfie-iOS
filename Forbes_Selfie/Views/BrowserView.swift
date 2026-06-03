import SwiftUI

struct BrowserView: UIViewControllerRepresentable {
    let url: URL
    var customUA: String? = nil
    var onComplete: ((String) -> Void)? = nil
    var onClose: (() -> Void)? = nil

    private static let defaultUA =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " +
        "AppleWebKit/537.36 (KHTML, like Gecko) " +
        "Chrome/124.0.0.0 Safari/537.36"

    // Extract code from URL query param
    private var sessionCode: String {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value ?? ""
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let ua = (customUA?.isEmpty == false) ? customUA! : BrowserView.defaultUA
        let vc = BrowserViewController(url: url, code: sessionCode, userAgent: ua)
        vc.onComplete = onComplete
        vc.onClose = onClose
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
