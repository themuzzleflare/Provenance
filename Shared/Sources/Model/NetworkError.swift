import Foundation

enum NetworkError: Error {
  case transportError(Error)
  case decodingError(Error)
  case encodingError(Error)
  case serverError(statusCode: Int)
  case noData
}

extension NetworkError {
  init?(data: Data?, response: URLResponse?, error: Error?) {
    if let error = error {
      self = .transportError(error)
      return
    }
    
    if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
      self = .serverError(statusCode: response.statusCode)
      return
    }
    
    if data == nil {
      self = .noData
    }
    return nil
  }
}

extension NetworkError {
  var title: String {
    switch self {
    case .transportError:
      return "Transport Error"
    case .decodingError:
      return "Decoding Error"
    case .encodingError:
      return "Encoding Error"
    case .serverError:
      return "Server Error"
    case .noData:
      return "No Data"
    }
  }
  
  var description: String {
    switch self {
    case let .transportError(error):
      return error.localizedDescription
    case let .decodingError(error):
      return error.localizedDescription
    case let .serverError(statusCode):
      return "\(statusCode.statusTitle): \(statusCode.statusDescription)"
    case .noData:
      return "No data."
    default:
      return "Unknown error."
    }
  }
}
