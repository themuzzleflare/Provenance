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
        if let accountId = configuration.account?.identifier {
            let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(accountId)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = [
                "Accept": "application/json",
                "Authorization": "Bearer \(appDefaults.apiKey)"
            ]
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error == nil {
                    if let decodedResponse = try? JSONDecoder().decode(SingleAccountResponse.self, from: data!) {
                        DispatchQueue.main.async {
                            entries.append(Entry(date: Date(), account: AvailableAccount(id: decodedResponse.data.id, displayName: decodedResponse.data.attributes.displayName, balance: decodedResponse.data.attributes.balance.valueShort)))
                            completion(Timeline(entries: entries, policy: .atEnd))
                        }
                    }
                }
            }
            .resume()
        } else {
            entries.append(Entry(date: Date(), account: nil))
            completion(Timeline(entries: entries, policy: .atEnd))
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
                                .foregroundColor(Color("AccentColour"))
                            Spacer()
                        }
                        Text(entry.account!.balance)
                            .font(.custom("CircularStd-Bold", size: 23))
                            .foregroundColor(family != .systemSmall ? .primary : Color("AccentColour"))
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
