import SwiftUI

struct LatestTransactionEntryView: View {
  let entry: LatestTransactionProvider.Entry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    Group {
      if let transaction = entry.transaction {
        switch family {
        case .systemSmall:
          VStack {
            Text(transaction.description)
              .font(.circularStdBold(size: 20))
            Text(transaction.amount)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .systemMedium, .systemLarge, .systemExtraLarge:
          VStack {
            Text("Latest Transaction")
              .font(.circularStdBold(size: 23))
              .foregroundColor(.accentColor)
            Spacer()
            TransactionCellView(transaction: transaction)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      } else if let error = entry.error {
        switch family {
        case .systemSmall:
          Text(error.description)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .systemMedium, .systemLarge, .systemExtraLarge:
          VStack {
            Text(error.title)
              .font(.circularStdBold(size: 18))
            Text(error.description)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    .background(Color.widgetBackground)
    .font(.circularStdBook(size: 16))
  }
}
