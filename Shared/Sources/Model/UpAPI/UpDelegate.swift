import Foundation
import Alamofire

final class UpDelegate: SessionDelegate {
  override func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    super.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    print("didSendBodyData")
  }

  override func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    super.urlSession(session, dataTask: dataTask, didReceive: data)
    print("didReceiveData")
  }

  override func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
    super.urlSession(session, taskIsWaitingForConnectivity: task)
    print("taskIsWaitingForConnectivity")
  }
}
