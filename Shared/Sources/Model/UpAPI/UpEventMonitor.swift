import Foundation
import Alamofire

final class UpEventMonitor: ClosureEventMonitor {
  override func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
    super.request(request, didCreateURLRequest: urlRequest)
#if DEBUG
    print(request.cURLDescription())
#endif
  }
}
