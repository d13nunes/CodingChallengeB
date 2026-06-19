import Foundation

protocol AvatarsAPIProtocol {
    func fetchUser(username: String) async -> Result<AvatarDTO, APIError>
}

class AvatarsAPI: AvatarsAPIProtocol {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol) {
        self.client = client
    }

    convenience init(session: URLSession) {
        self.init(client: HTTPClient(session: session))
    }

    func fetchUser(username: String) async -> Result<AvatarDTO, APIError> {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else {
            return .failure(.invalidURL)
        }
        let result = await client.get(url, as: AvatarDTO.self)
        return result.map { $0.value }
    }
}
