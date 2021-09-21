import SwiftUI

struct AccountBalanceEntryView: View {
  let entry: AccountBalanceProvider.Entry
  @Environment(\.widgetFamily) private var family
  var body: some View {
    Group {
      if let account = entry.account {
        switch family {
        case .systemSmall:
          VStack {
            Text(account.balance)
              .font(.circularStdBold(size: 20))
            Text(account.displayName)
          }
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
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
