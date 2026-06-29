import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed
    case badResponse
    case networkError
    case decodeError
    case notFound
    case rateLimited(reset: Date?)
    case unmapped(String)
    case unknown
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed:
            return "The request failed."
        case .badResponse:
            return "Unexpected server response."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .decodeError:
            return "Couldn't read the server response."
        case .notFound:
            return "Not found."
        case let .rateLimited(reset):
            guard let reset else {
                return "GitHub API rate limit reached. Please try again later."
            }
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "GitHub API rate limit reached. Try again after \(formatter.string(from: reset))."
        case let .unmapped(message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

extension HTTPURLResponse {
    /// GitHub signals throttling with 403/429 and an `x-ratelimit-remaining: 0` header.
    var isRateLimited: Bool {
        guard statusCode == 403 || statusCode == 429 else { return false }
        if let remaining = value(forHTTPHeaderField: "x-ratelimit-remaining") {
            return remaining == "0"
        }
        // 429 without the header is still a throttle response.
        return statusCode == 429
    }

    /// Epoch seconds in `x-ratelimit-reset`, parsed into the time the quota refreshes.
    var rateLimitReset: Date? {
        guard let value = value(forHTTPHeaderField: "x-ratelimit-reset"),
              let epoch = TimeInterval(value) else { return nil }
        return Date(timeIntervalSince1970: epoch)
    }
}

/// A decoded payload paired with its HTTP response, so callers that need
/// response metadata (e.g. the `Link` header for pagination) can reach it.
struct APIResponse<Value> {
    let value: Value
    let response: HTTPURLResponse
}

protocol HTTPClientProtocol {
    func get<Value: Decodable>(_ url: URL, as type: Value.Type) async -> Result<APIResponse<Value>, APIError>
}

/// Single place every API client funnels through: performs the request, applies
/// the shared rate-limit / status / decode handling, and maps failures to `APIError`.
final class HTTPClient: HTTPClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func get<Value: Decodable>(_ url: URL, as _: Value.Type = Value.self) async -> Result<APIResponse<Value>, APIError> {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.badResponse)
            }
            if http.isRateLimited {
                return .failure(.rateLimited(reset: http.rateLimitReset))
            }
            if http.statusCode == 404 {
                return .failure(.notFound)
            }
            guard http.statusCode == 200 else {
                return .failure(.badResponse)
            }
            do {
                let value = try decoder.decode(Value.self, from: data)
                return .success(APIResponse(value: value, response: http))
            } catch {
                return .failure(.decodeError)
            }
        } catch {
            return .failure(.unmapped(error.localizedDescription))
        }
    }
}
