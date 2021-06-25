import Foundation

struct ErrorResponse: Decodable {
    var errors: [ErrorObject] // The list of errors returned in this response.

    struct ErrorObject: Decodable {
        var status: String // The HTTP status code associated with this error. This can also be obtained from the response headers. The status indicates the broad type of error according to HTTP semantics.
        var title: String // A short description of this error. This should be stable across multiple occurrences of this type of error and typically expands on the reason for the status code.
        var detail: String // A detailed description of this error. This should be considered unique to individual occurrences of an error and subject to change. It is useful for debugging purposes.
        var source: ErrorSource? // If applicable, location in the request that this error relates to. This may be a parameter in the query string, or a an attribute in the request body.

        struct ErrorSource: Decodable {
            var parameter: String? // If this error relates to a query parameter, the name of the parameter.
            var pointer: String? // If this error relates to an attribute in the request body, a rfc-6901 JSON pointer to the attribute.
        }
    }
}
