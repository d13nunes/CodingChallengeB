import Foundation

struct RepoValue: Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: URL?
    let stargazersCount: Int
    let forksCount: Int
    let language: String?
}
