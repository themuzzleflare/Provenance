import Foundation
import Alamofire

final class UpDelegate: SessionDelegate {
  override func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    super.urlSession(session, dataTask: dataTask, didReceive: data)
#if DEBUG
    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
      print(errorResponse)
    }
#endif
  }
}
