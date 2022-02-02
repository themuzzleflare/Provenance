import Foundation
import Alamofire

final class UpInterceptor: RequestInterceptor {
  func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest
    if urlRequest.value(forHTTPHeaderField: "Authorization") == nil {
      urlRequest.headers.add(.authorization(bearerToken: Store.provenance.apiKey))
    }
    completion(.success(urlRequest))
  }
}
