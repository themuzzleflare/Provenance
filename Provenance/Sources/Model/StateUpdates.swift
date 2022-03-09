import Foundation

enum StateUpdates {
  static func updateState(state: inout UIState,
                          contents: [Any],
                          filteredContents: [Any],
                          noContent: Bool,
                          error: String) {
    if filteredContents.isEmpty && error.isEmpty {
      if contents.isEmpty && !noContent {
        state = .initialLoad
      } else {
        state = .noContent
      }
    } else {
      if !error.isEmpty {
        state = .error(error)
      } else {
        state = .ready
      }
    }
  }
}
