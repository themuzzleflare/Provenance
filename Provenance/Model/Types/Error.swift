import Foundation

struct ErrorResponse: Decodable {
    var errors: [ErrorObject]
}

struct ErrorObject: Decodable {
    var status: String
    var title: String
    var detail: String
    var source: ErrorSource?
}

struct ErrorSource: Decodable {
    var parameter: String?
    var pointer: String?
}
