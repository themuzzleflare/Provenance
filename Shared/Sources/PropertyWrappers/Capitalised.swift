import Foundation

@propertyWrapper
struct Capitalized {
  var wrappedValue: String {
    didSet { wrappedValue = wrappedValue.capitalized }
  }

  init(wrappedValue: String) {
    self.wrappedValue = wrappedValue.capitalized
  }
}
