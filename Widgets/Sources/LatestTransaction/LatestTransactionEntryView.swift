import SwiftUI

struct LatestTransactionEntryView: View {
  @Environment(\.widgetFamily) private var family

  let entry: LatestTransactionProvider.Entry

  var body: some View {
    Group {
      if let transaction = entry.transaction {
        LatestTransactionView(family: family, transaction: transaction)
          .widgetURL("provenance://transactions/\(transaction.id)".url)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = entry.error {
        ErrorView(family: family, error: error)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .background(Color.widgetBackground)
    .font(.circularStdBook(size: 16))
  }
}
