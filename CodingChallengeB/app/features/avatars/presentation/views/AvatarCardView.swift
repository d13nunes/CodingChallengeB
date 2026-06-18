import SwiftUI

struct AvatarCardView: View {
    let username: String
    let avatarUrl: URL?

    var body: some View {
        VStack(spacing: 6) {
            CachedAsyncImage(url: avatarUrl) {
                $0.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            } error: {
                Image(systemName: "person.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            Text(username)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
