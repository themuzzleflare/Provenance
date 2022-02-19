import SwiftUI
import WidgetKit

struct AccountBalance: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: Widgets.accountBalance.kind,
                        intent: AccountSelectionIntent.self,
                        provider: AccountBalanceProvider(),
                        content: { AccountBalanceEntryView(entry: $0) })
      .configurationDisplayName(Widgets.accountBalance.name)
      .description(Widgets.accountBalance.description)
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
