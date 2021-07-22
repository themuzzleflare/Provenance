import Foundation

struct Pagination: Codable {
    var prev: String? // The link to the previous page in the results. If this value is null there is no previous page.

    var next: String? // The link to the next page in the results. If this value is null there is no next page.
}
