import Foundation

enum UIState: Equatable {
  case initialLoad
  case error(String)
  case noContent
  case ready
}
