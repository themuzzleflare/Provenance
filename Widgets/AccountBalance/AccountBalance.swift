import SwiftUI
import WidgetKit

struct AccountBalance: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: "accountBalanceWidget", intent: AccountSelectionIntent.self, provider: AccountBalanceProvider()) { (entry) in
      AccountBalanceEntryView(entry: entry)
    }
    .configurationDisplayName("Account Balance")
    .description("Displays the balance of your selected account.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct AccountBalance_Previews: PreviewProvider {
  static let families: [WidgetFamily] = [.systemSmall, .systemMedium]
  static var previews: some View {
    ForEach(families, id: \.self) { (family) in
      AccountBalanceEntryView(entry: .placeholder)
        .previewDisplayName(family.description)
        .previewContext(WidgetPreviewContext(family: family))
        .preferredColorScheme(.dark)
    }
  }
}
