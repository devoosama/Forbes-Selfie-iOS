import SwiftUI

struct BrowserView: UIViewControllerRepresentable {
    let url: URL
    var onComplete: ((String) -> Void)? = nil
    var onClose: (() -> Void)? = nil

    // Extract code from URL query param
    private var sessionCode: String {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value ?? ""
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = BrowserViewController(url: url, code: sessionCode)
        vc.onComplete = onComplete
        vc.onClose = onClose
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
