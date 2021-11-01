import SwiftUI

struct LatestTransactionEntryView: View {
  let entry: LatestTransactionProvider.Entry

  var body: some View {
    Group {
      if let transaction = entry.transaction {
        LatestTransactionView(transaction: transaction)
          .widgetURL("provenance://transactions/\(transaction.id)".url)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = entry.error {
        ErrorView(error: error)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .background(Color.widgetBackground)
    .font(.circularStdBook(size: 16))
  }
}
