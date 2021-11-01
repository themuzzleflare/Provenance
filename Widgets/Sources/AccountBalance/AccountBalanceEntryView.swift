import SwiftUI

struct AccountBalanceEntryView: View {
  let entry: AccountBalanceProvider.Entry

  var body: some View {
    Group {
      if let account = entry.account {
        AccountBalanceView(account: account)
          .widgetURL("provenance://accounts/\(account.id)".url)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = entry.error {
        ErrorView(error: error)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        Text("Edit widget to choose an account")
          .foregroundColor(.secondary)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .background(Color.widgetBackground)
    .font(.circularStdBook(size: 16))
  }
}
