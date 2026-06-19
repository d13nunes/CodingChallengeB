import SwiftUI

struct RepoRowView: View {
    let repo: RepoValue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(repo.name)
                .font(.headline)
            if let description = repo.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 12) {
                Label("\(repo.stargazersCount)", systemImage: "star")
                Label("\(repo.forksCount)", systemImage: "tuningfork")
                if let language = repo.language {
                    Text(language)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .font(.caption).padding(.bottom, 4)
            Divider()
        }
        .padding(.all, 4)
    }
}

#Preview {
    RepoRowView(repo: .init(id: 1, name: "Repo name", fullName: "A big repo name", description: "The description of the repo", htmlUrl: URL(string: "https://github.com")!, stargazersCount: 123, forksCount: 234, language: "Swift"))
}
