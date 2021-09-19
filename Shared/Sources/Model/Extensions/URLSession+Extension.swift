import Foundation

typealias DataResult = Result<Data, NetworkError>

extension URLSession {
  func dataTask(with request: URLRequest, resultHandler: @escaping (DataResult) -> Void) -> URLSessionDataTask {
    return self.dataTask(with: request) { (data, response, error) in
      if let networkError = NetworkError(data: data, response: response, error: error) {
        resultHandler(.failure(networkError))
        return
      }
      resultHandler(.success(data!))
    }
  }

  func dataTask(with request: URLRequest, errorHandler: @escaping (NetworkError?) -> Void) -> URLSessionDataTask {
    return self.dataTask(with: request) { (data, response, error) in
      errorHandler(NetworkError(data: data, response: response, error: error))
    }
  }
}
