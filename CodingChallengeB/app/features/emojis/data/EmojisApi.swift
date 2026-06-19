import Foundation

protocol EmojisAPIProtocol {
    func fetchAll() async -> Result<[EmojiDTO], APIError>
}

class EmojisAPI: EmojisAPIProtocol {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol) {
        self.client = client
    }

    convenience init(session: URLSession) {
        self.init(client: HTTPClient(session: session))
    }

    func fetchAll() async -> Result<[EmojiDTO], APIError> {
        guard let url = URL(string: "https://api.github.com/emojis") else {
            return .failure(.invalidURL)
        }
        let result = await client.get(url, as: [String: String].self)
        return result.map { response in
            response.value.map { EmojiDTO(name: $0.key, url: $0.value) }
        }
    }
}
