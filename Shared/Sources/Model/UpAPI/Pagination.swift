import Foundation

struct Pagination: Codable {
    /// The link to the previous page in the results. If this value is `null` there is no previous page.
  var prev: String?
  
    /// The link to the next page in the results. If this value is `null` there is no next page.
  var next: String?
}
