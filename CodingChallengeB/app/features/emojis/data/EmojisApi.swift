import Combine
import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed
    case badResponse
    case networkError
    case decodeError
    case unmapped(String)
    case unknown
}

protocol EmojisAPIProtocol {
    func fetchAll() async -> Result<[EmojiDTO], APIError>
}

class EmojisAPI: EmojisAPIProtocol {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetchAll() async -> Result<[EmojiDTO], APIError> {
        guard let url = URL(string: "https://api.github.com/emojis") else {
            return .failure(APIError.invalidURL)
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return .failure(APIError.badResponse)
            }
            let dictiornary = try JSONDecoder().decode([String: String].self, from: data)
            let emojis = dictiornary.map { key, value in
                EmojiDTO(name: key, url: value)
            }
            return .success(emojis)
        } catch {
            debugPrint("error: \(error.localizedDescription)")
            return .failure(APIError.unmapped(error.localizedDescription))
        }
    }
}
