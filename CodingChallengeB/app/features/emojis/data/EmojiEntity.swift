import Foundation
import SwiftData

@Model
final class EmojiEntity {
    @Attribute(.unique)
    var id: UUID = UUID()
    var name: String
    var urlString: String

    init(name: String, urlString: String) {
        self.name = name
        self.urlString = urlString
    }
}
