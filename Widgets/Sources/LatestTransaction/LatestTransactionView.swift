import SwiftUI
import WidgetKit

struct LatestTransactionView: View {
  @Environment(\.widgetFamily) private var family

  let transaction: LatestTransactionModel

  var body: some View {
    switch family {
    case .systemSmall:
      VStack {
        Text(transaction.description)
          .font(.circularStdBold(size: 20))
        Text(transaction.amount)
      }
    case .systemMedium, .systemLarge, .systemExtraLarge:
      VStack {
        Text("Latest Transaction")
          .font(.circularStdBold(size: 23))
          .foregroundColor(.accentColor)
        Spacer()
        TransactionCellView(transaction: transaction)
      }
    @unknown default:
      VStack {
        Text(transaction.description)
          .font(.circularStdBold(size: 20))
        Text(transaction.amount)
      }
    }
  }
}
