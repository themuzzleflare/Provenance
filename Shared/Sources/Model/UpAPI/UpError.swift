import Foundation

enum UpError: Error {
  case badRequest(detail: String)
  case notAuthorised(detail: String)
  case notFound(detail: String)
  case invalidRequest(detail: String)
  case tooManyRequests(detail: String)
  case serverSideError(detail: String)
  case other(detail: String)

  init(statusCode: Int, detail: String) {
    switch statusCode {
    case 400:
      self = .badRequest(detail: detail)
    case 401:
      self = .notAuthorised(detail: detail)
    case 404:
      self = .notFound(detail: detail)
    case 422:
      self = .invalidRequest(detail: detail)
    case 429:
      self = .tooManyRequests(detail: detail)
    case 500, 502, 503, 504:
      self = .serverSideError(detail: detail)
    default:
      self = .other(detail: detail)
    }
  }
}

// MARK: -

extension UpError {
  var title: String {
    switch self {
    case .badRequest:
      return "Bad request"
    case .notAuthorised:
      return "Not authorized"
    case .notFound:
      return "Not found"
    case .invalidRequest:
      return "Invalid request"
    case .tooManyRequests:
      return "Too many requests"
    case .serverSideError:
      return "Server-side errors"
    case .other:
      return "Error"
    }
  }

  var description: String {
    switch self {
    case .badRequest:
      return "Typically a problem with the query string or an encoding error."
    case .notAuthorised:
      return "The request was not authenticated."
    case .notFound:
      return "Either the endpoint does not exist, or the requested resource does not exist."
    case .invalidRequest:
      return "The request contains invalid data and was not processed."
    case .tooManyRequests:
      return "You have been rate limited—try later, ideally with exponential backoff."
    case .serverSideError:
      return "Try again later."
    case .other:
      return "Unknown error."
    }
  }
}

// MARK: - LocalizedError

extension UpError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .badRequest(detail):
      return detail
    case let .notAuthorised(detail):
      return detail
    case let .notFound(detail):
      return detail
    case let .invalidRequest(detail):
      return detail
    case let .tooManyRequests(detail):
      return detail
    case let .serverSideError(detail):
      return detail
    case let .other(detail):
      return detail
    }
  }
}
