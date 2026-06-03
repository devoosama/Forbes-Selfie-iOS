import SwiftUI
import UIKit

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - OTP State
    @Published var code: [String] = ["", "", "", ""]
    @Published var errorMessage: String = ""

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var showBrowser: Bool = false
    @Published var browserURL: URL? = nil

    // MARK: - Alert
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""

    // MARK: - Status
    @Published var statusText: String = "Ready"
    @Published var statusDotColor: Color = Color(hex: "#1A2744")
    @Published var statusTextColor: Color = Color(hex: "#4A6A8A")

    // MARK: - Computed
    var codeIsFull: Bool { code.allSatisfy { $0.count == 1 } }
    var fullCode: String { code.joined() }

    private let sessionService = SessionService()

    // MARK: - Start Session
    func startSession() {
        guard codeIsFull else {
            showError("Please enter the 4-digit code")
            return
        }

        errorMessage = ""
        isLoading = true
        setStatus("Connecting...", dot: Color(hex: "#0EA5E9"), text: Color(hex: "#0EA5E9"))

        Task {
            do {
                let session = try await sessionService.getSession(code: fullCode)

                switch session.status {
                case "active", "used":
                    setStatus("Opening liveness...", dot: Color(hex: "#F59E0B"), text: Color(hex: "#F59E0B"))
                    let url = buildLivenessURL(code: fullCode)
                    browserURL = url
                    showBrowser = true
                    // Reset OTP after launching
                    Task {
                        try? await Task.sleep(nanoseconds: 800_000_000)
                        resetCode()
                        setStatus("Session launched", dot: Color(hex: "#10B981"), text: Color(hex: "#10B981"))
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        setStatus("Ready", dot: Color(hex: "#1A2744"), text: Color(hex: "#4A6A8A"))
                    }

                case "completed":
                    setStatus("Already completed", dot: Color(hex: "#F59E0B"), text: Color(hex: "#F59E0B"))
                    showError("This session is already completed.")

                case "expired":
                    setStatus("Session expired", dot: Color(hex: "#EF4444"), text: Color(hex: "#EF4444"))
                    showError("This code has expired. Please get a new one.")

                default:
                    setStatus("Unknown status", dot: Color(hex: "#EF4444"), text: Color(hex: "#EF4444"))
                    showError("Unknown session status: \(session.status)")
                }

            } catch SessionError.notFound {
                setStatus("Code not found", dot: Color(hex: "#EF4444"), text: Color(hex: "#EF4444"))
                showError("Code \(fullCode) not found. Check the code and try again.")

            } catch SessionError.serverError(let msg) {
                setStatus("Server error", dot: Color(hex: "#EF4444"), text: Color(hex: "#EF4444"))
                showError("Server error: \(msg)")

            } catch {
                setStatus("Connection failed", dot: Color(hex: "#EF4444"), text: Color(hex: "#EF4444"))
                showError("Cannot connect to server. Check your internet connection.")
            }

            isLoading = false
        }
    }

    // MARK: - Build Liveness URL
    private func buildLivenessURL(code: String) -> URL {
        // Load the liveness HTML from bundle
        // WKWebView will load this local HTML which then injects content.js
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "web-sdk.spain.prod.ozforensics.com"
        comps.path = "/blsinternational/plugin_liveness.php"
        comps.queryItems = [
            URLQueryItem(name: "code", value: code)
        ]
        return comps.url!
    }

    // MARK: - Helpers
    func resetCode() {
        code = ["", "", "", ""]
    }

    private func showError(_ msg: String) {
        errorMessage = msg
        // Vibrate
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }

    func setStatus(_ text: String, dot: Color, text textColor: Color) {
        statusText = text
        statusDotColor = dot
        statusTextColor = textColor
    }

}
