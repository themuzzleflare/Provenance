import Foundation

extension URL {
  func appendingQueryParameters(_ parametersDictionary: [String: String]) -> URL {
    let urlString = String(
      format: "%@?%@",
      self.absoluteString,
      parametersDictionary.queryParameters
    )
    return URL(string: urlString)!
  }
}
