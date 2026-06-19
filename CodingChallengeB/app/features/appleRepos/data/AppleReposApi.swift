import Foundation

struct PaginatedResult<Value> {
    let items: [Value]
    let hasMore: Bool
}

protocol AppleReposAPIProtocol {
    func fetch(page: Int, size: Int) async -> Result<PaginatedResult<RepoDTO>, APIError>
}

class AppleReposApi: AppleReposAPIProtocol {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetch(page: Int, size: Int) async -> Result<PaginatedResult<RepoDTO>, APIError> {
        guard let url = URL(string: "https://api.github.com/users/apple/repos?page=\(page)&per_page=\(size)") else {
            return .failure(.invalidURL)
        }
        do {
            let (data, response) = try await session.data(from: url)
            let httpResponse = response as? HTTPURLResponse
            guard httpResponse?.statusCode == 200 else {
                return .failure(.badResponse)
            }
            let linkHeader = httpResponse?.allHeaderFields["Link"] as? String
            let hasMore = hasMoreToLoad(linkHeader: linkHeader)
            let repos = try JSONDecoder().decode([RepoDTO].self, from: data)
            return .success(PaginatedResult(items: repos, hasMore: hasMore))
        } catch {
            return .failure(.unmapped(error.localizedDescription))
        }
    }

    private func hasMoreToLoad(linkHeader: String?) -> Bool {
        guard let linkHeader else { return false }
        return linkHeader.contains("rel=\"next\"")
    }
}
