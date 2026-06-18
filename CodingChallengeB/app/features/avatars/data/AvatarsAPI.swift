import Foundation

protocol AvatarsAPIProtocol {
    func fetchUser(username: String) async -> Result<AvatarDTO, APIError>
}

class AvatarsAPI: AvatarsAPIProtocol {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetchUser(username: String) async -> Result<AvatarDTO, APIError> {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else {
            return .failure(.invalidURL)
        }
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return .failure(.badResponse)
            }
            let dto = try JSONDecoder().decode(AvatarDTO.self, from: data)
            return .success(dto)
        } catch {
            return .failure(.unmapped(error.localizedDescription))
        }
    }
}
