import SwiftUI
import WidgetKit

struct AccountBalanceProvider: IntentTimelineProvider {
    typealias Entry = AccountBalanceModel
    typealias Intent = AccountSelectionIntent

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: "Up Account", balance: "$123.95"))
    }

    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: "Up Account", balance: "$123.95")))
    }

    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [Entry] = []

        guard let accountId = configuration.account?.identifier else {
            entries.append(Entry(date: Date(), account: nil))
            completion(Timeline(entries: entries, policy: .atEnd))
            return
        }

        Up.retrieveAccount(for: accountId) { result in
            switch result {
                case .success(let account):
                    entries.append(Entry(date: Date(), account: AvailableAccount(id: account.id, displayName: account.attributes.displayName, balance: account.attributes.balance.valueShort)))

                    completion(Timeline(entries: entries, policy: .atEnd))
                case .failure(let error):
                    entries.append(Entry(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: errorString(for: error), balance: "Error")))

                    completion(Timeline(entries: entries, policy: .atEnd))
            }
        }
    }
}

struct AccountBalanceModel: TimelineEntry {
    let date: Date
    var account: AvailableAccount?
}

struct AccountBalanceEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: AccountBalanceProvider.Entry

    @ViewBuilder
    var body: some View {
        ZStack {
            VStack {
                switch entry.account {
                    case nil:
                        Text("Edit widget to choose an account")
                            .font(.custom("CircularStd-Book", size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    default:
                        if family != .systemSmall {
                            Text("Account Balance")
                                .font(.custom("CircularStd-Bold", size: 23))
                                .foregroundColor(Color("AccentColor"))
                            Spacer()
                        }
                        Text(entry.account!.balance)
                            .font(.custom("CircularStd-Bold", size: 23))
                            .foregroundColor(family != .systemSmall ? .primary : Color("AccentColor"))
                        Text(entry.account!.displayName)
                            .font(.custom("CircularStd-Book", size: 17))
                            .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("WidgetBackground"))
    }
}

struct AccountBalance: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "accountBalanceWidget", intent: AccountSelectionIntent.self, provider: AccountBalanceProvider()) { entry in
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
        ForEach(families, id: \.self) { family in
            AccountBalanceEntryView(entry: AccountBalanceModel(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: "Up Account", balance: "$123.95")))
                .previewDisplayName(family.description)
                .previewContext(WidgetPreviewContext(family: family))
                .colorScheme(.dark)
        }
    }
}
