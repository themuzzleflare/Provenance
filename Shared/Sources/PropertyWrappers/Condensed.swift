import Foundation

@propertyWrapper
struct Condensed: Codable {
  private var string: String?
  private(set) var projectedValue: String?

  var wrappedValue: String? {
    get {
      return string
    }
    set {
      string = newValue?.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression)
      projectedValue = newValue
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.wrappedValue = try? container.decode(String.self)
  }
}
