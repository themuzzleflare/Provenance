import SwiftUI
import WidgetKit

struct LatestTransaction: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(kind: "latestTransactionWidget", intent: DateStyleSelectionIntent.self, provider: LatestTransactionProvider()) { (entry) in
      LatestTransactionEntryView(entry: entry)
    }
    .configurationDisplayName("Latest Transaction")
    .description("Displays your latest transaction.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct LatestTransaction_Previews: PreviewProvider {
  static let families: [WidgetFamily] = [.systemSmall, .systemMedium]
  static var previews: some View {
    ForEach(families, id: \.self) { (family) in
      LatestTransactionEntryView(entry: .placeholder)
        .previewDisplayName(family.description)
        .previewContext(WidgetPreviewContext(family: family))
        .preferredColorScheme(.dark)
    }
  }
}
