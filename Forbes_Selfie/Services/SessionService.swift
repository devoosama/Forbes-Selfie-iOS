import Foundation

// MARK: - Session Model
struct SessionData: Decodable {
    let status: String
    let url: String?
    let userAgent: String?
    let livenessId: String?
    let code: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case url
        case userAgent = "userAgent"
        case livenessId = "liveness_id"
        case code
        case createdAt = "created_at"
    }
}

// MARK: - API Response wrapper
private struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

// MARK: - Errors
enum SessionError: Error {
    case notFound
    case serverError(String)
    case decodingError
    case networkError
}

// MARK: - Session Service
final class SessionService {
    private let baseURL = "https://houarimed.tech/api"

    // GET /getData/{code}
    func getSession(code: String) async throws -> SessionData {
        guard let url = URL(string: "\(baseURL)/getData/\(code)") else {
            throw SessionError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionError.networkError
        }

        if httpResponse.statusCode == 404 {
            throw SessionError.notFound
        }

        if httpResponse.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SessionError.serverError(msg)
        }

        do {
            let decoded = try JSONDecoder().decode(APIResponse<SessionData>.self, from: data)
            if let sessionData = decoded.data {
                return sessionData
            }
            // Try direct decode
            return try JSONDecoder().decode(SessionData.self, from: data)
        } catch {
            // Try direct decode as fallback
            do {
                return try JSONDecoder().decode(SessionData.self, from: data)
            } catch {
                throw SessionError.decodingError
            }
        }
    }

    // PATCH /updateSession/{code}
    func updateSession(code: String, status: String) async {
        guard let url = URL(string: "\(baseURL)/updateSession/\(code)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["status": status])
        request.timeoutInterval = 10

        _ = try? await URLSession.shared.data(for: request)
    }

    // POST /result/{code}
    func postResult(code: String, livenessId: String) async {
        guard let url = URL(string: "\(baseURL)/result/\(code)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["liveness_id": livenessId])
        request.timeoutInterval = 10

        _ = try? await URLSession.shared.data(for: request)
    }
}
