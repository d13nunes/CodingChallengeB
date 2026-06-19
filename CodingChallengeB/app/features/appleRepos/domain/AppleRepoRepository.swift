import Combine
import Foundation

enum AppleRepoRepositoryError: Error {
    case failed(reason: String)
}

extension AppleRepoRepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .failed(reason):
            return reason
        }
    }
}

protocol AppleRepoRepositoryProtocol {
    func fetch(page: Int, pageSize: Int) async -> Result<(repos: [RepoValue], hasMore: Bool), AppleRepoRepositoryError>
}

@MainActor
class AppleRepoRepository: AppleRepoRepositoryProtocol {
    private let api: AppleReposAPIProtocol

    init(api: AppleReposAPIProtocol) {
        self.api = api
    }

    func fetch(page: Int, pageSize: Int = 10) async -> Result<(repos: [RepoValue], hasMore: Bool), AppleRepoRepositoryError> {
        let result = await api.fetch(page: page, size: pageSize)
        switch result {
        case let .failure(error):
            return .failure(.failed(reason: error.localizedDescription))
        case let .success(paginatedResult):
            return .success((paginatedResult.items.map { $0.toValue() }, paginatedResult.hasMore))
        }
    }
}

private extension RepoDTO {
    func toValue() -> RepoValue {
        RepoValue(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            htmlUrl: URL(string: htmlUrl),
            stargazersCount: stargazersCount,
            forksCount: forksCount,
            language: language
        )
    }
}
