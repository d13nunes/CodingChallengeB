import Foundation

struct PaginatedResult<Value> {
    let items: [Value]
    let hasMore: Bool
}

protocol AppleReposAPIProtocol {
    func fetch(page: Int, size: Int) async -> Result<PaginatedResult<RepoDTO>, APIError>
}

class AppleReposApi: AppleReposAPIProtocol {
    private let client: HTTPClientProtocol

    init(client: HTTPClientProtocol) {
        self.client = client
    }

    convenience init(session: URLSession) {
        self.init(client: HTTPClient(session: session))
    }

    func fetch(page: Int, size: Int) async -> Result<PaginatedResult<RepoDTO>, APIError> {
        guard let url = URL(string: "https://api.github.com/users/apple/repos?page=\(page)&per_page=\(size)") else {
            return .failure(.invalidURL)
        }
        let result = await client.get(url, as: [RepoDTO].self)
        return result.map { response in
            let linkHeader = response.response.allHeaderFields["Link"] as? String
            return PaginatedResult(items: response.value, hasMore: hasMoreToLoad(linkHeader: linkHeader))
        }
    }

    private func hasMoreToLoad(linkHeader: String?) -> Bool {
        guard let linkHeader else { return false }
        return linkHeader.contains("rel=\"next\"")
    }
}
