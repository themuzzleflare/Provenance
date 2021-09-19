import SwiftUI

struct TransactionCellView: View {
  let transaction: LatestTransactionModel
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(transaction.description)
          .font(.circularStdMedium(size: UIFont.labelFontSize))
        Text(transaction.creationDate)
          .font(.circularStdBookItalic(size: UIFont.smallSystemFontSize))
          .foregroundColor(.secondary)
      }
      .multilineTextAlignment(.leading)
      Spacer()
      Text(transaction.amount)
        .multilineTextAlignment(.trailing)
        .foregroundColor(transaction.colour)
    }
  }
}
