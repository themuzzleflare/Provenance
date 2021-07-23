import Foundation
import SwiftyBeaver

enum NetworkError: Error {
    case transportError(Error)
    case serverError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case noData
}

extension NetworkError {
    init?(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            self = .transportError(error)
            log.error(errorString(for: .transportError(error)))
            return
        }

        if let response = response as? HTTPURLResponse,
           !(200...299).contains(response.statusCode) {
            self = .serverError(statusCode: response.statusCode)
            log.error(errorString(for: .serverError(statusCode: response.statusCode)))
            return
        }

        if data == nil {
            self = .noData
            log.error(errorString(for: .noData))
        }

        return nil
    }
}
