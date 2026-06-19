import Foundation

struct RepoDTO: Decodable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let stargazersCount: Int
    let forksCount: Int
    let language: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case htmlUrl = "html_url"
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
    }
}
