import SwiftUI

struct EmojiCardView: View {
    let name: String
    let imageURL: URL?

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: imageURL) {
                $0
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            } error: {
                Text("Error")
            }
        }
    }
}

#Preview {
    EmojiCardView(name: "thumbsup", imageURL: URL(string: "https://github.githubassets.com/images/icons/emoji/unicode/1f1f8-1f1ef.png?v8")!)
        .frame(width: 80, height: 80)
}
