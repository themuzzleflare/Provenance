import Foundation

func errorString(for error: NetworkError) -> String {
    switch error {
    case .transportError(let terror):
        return "Error: \(terror.localizedDescription)"
    case .serverError(statusCode: let statusCode):
        let detail = statusDetail(for: statusCode)
        return "\(detail.title): \(detail.detail)"
    case .decodingError(let derror):
        return "Error: \(derror.localizedDescription)"
    case .noData:
        return "Error: No data."
    default:
        return "Error: Unknown error."
    }
}

func statusDetail(for statusCode: Int) -> (title: String, detail: String) {
    switch statusCode {
    case 200:
        return (title: "Successful response", detail: "Everything worked as intended")
    case 201:
        return (title: "Successful response",
                detail: "A new resource was created successfully—Typically used with POST requests.")
    case 204:
        return (title: "Successful response", detail: "No content—typically used with DELETE requests.")
    case 400:
        return (title: "Bad request", detail: "Typically a problem with the query string or an encoding error.")
    case 401:
        return (title: "Not authorised", detail: "The request was not authenticated.")
    case 403:
        return (title: "Forbidden", detail: "Each transaction may have up to 6 tags.")
    case 404:
        return (title: "Not found",
                detail: "Either the endpoint does not exist, or the requested resource does not exist.")
    case 422:
        return (title: "Invalid request", detail: "The request contains invalid data and was not processed.")
    case 429:
        return (title: "Too many requests",
                detail: "You have been rate limited—try later, ideally with exponential backoff.")
    case 500, 502, 503, 504:
        return (title: "Server-side error", detail: "Try again later.")
    default:
        return (title: "Network error", detail: "Unknown network error.")
    }
}
