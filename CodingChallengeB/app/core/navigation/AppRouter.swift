import Combine
import Foundation
import SwiftUI

@MainActor class AppRouter: ObservableObject {
  @Published  var navigationPath: [Route] = []
  
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
}
