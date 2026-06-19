import Combine
import Foundation
import SwiftUI

@MainActor @Observable
class AppRouter {
    var navigationPath: [Route] = []

    func push(_ destination: Route) {
        navigationPath.append(destination)
    }

    func pop() {
        navigationPath.removeLast()
    }
}

enum Route: Hashable {
    case main
    case emojiesList
    case avatarsList
    case appleRepos
}
