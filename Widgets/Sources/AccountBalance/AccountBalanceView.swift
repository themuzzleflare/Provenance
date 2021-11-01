import SwiftUI
import WidgetKit

struct AccountBalanceView: View {
  @Environment(\.widgetFamily) private var family

  let account: AccountBalanceModel

  var body: some View {
    switch family {
    case .systemSmall:
      VStack {
        Text(account.balance)
          .font(.circularStdBold(size: 20))
        Text(account.displayName)
      }
    case .systemMedium, .systemLarge, .systemExtraLarge:
      VStack {
        Text("Account Balance")
          .font(.circularStdBold(size: 23))
          .foregroundColor(.accentColor)
        Spacer()
        Text(account.balance)
          .font(.circularStdBold(size: 20))
        Text(account.displayName)
      }
    @unknown default:
      VStack {
        Text(account.balance)
          .font(.circularStdBold(size: 20))
        Text(account.displayName)
      }
    }
  }
}
