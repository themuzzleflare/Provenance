import SwiftUI
import WidgetKit
import Alamofire

struct ErrorView: View {
  @Environment(\.widgetFamily) private var family

  let error: AFError

  var body: some View {
    switch family {
    case .systemSmall:
      Text(error.localizedDescription)
    case .systemMedium, .systemLarge, .systemExtraLarge:
      VStack {
        Text("Error")
          .font(.circularStdBold(size: 18))
        Text(error.localizedDescription)
      }
    @unknown default:
      Text(error.localizedDescription)
    }
  }
}
