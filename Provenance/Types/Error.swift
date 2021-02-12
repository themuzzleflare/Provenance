import Foundation

struct ErrorResponse: Codable, Hashable {
    var errors: [ErrorObject]
}

struct ErrorObject: Codable, Hashable {
    var status: String
    var title: String
    var detail: String
    var source: ErrorSource?
}

struct ErrorSource: Codable, Hashable {
    var parameter: String?
    var pointer: String?
}
