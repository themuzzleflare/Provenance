import Foundation
import Alamofire

final class UpEventMonitor: ClosureEventMonitor {
  override func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
    super.request(request, didCreateURLRequest: urlRequest)
    print(request.cURLDescription())
  }

  override func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    super.urlSession(session, dataTask: dataTask, didReceive: data)
    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
      print(errorResponse)
    }
  }
}
