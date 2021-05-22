import SwiftUI
import WidgetKit

struct AccountBalanceProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> AccountBalanceModel {
        AccountBalanceModel(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: "Up Account", balance: "$123.95"))
    }

    func getSnapshot(for configuration: AccountSelectionIntent, in context: Context, completion: @escaping (AccountBalanceModel) -> Void) {
        let entry = AccountBalanceModel(date: Date(), account: AvailableAccount(id: UUID().uuidString, displayName: "Up Account", balance: "$123.95"))
        completion(entry)
    }

    func getTimeline(for configuration: AccountSelectionIntent, in context: Context, completion: @escaping (Timeline<AccountBalanceModel>) -> Void) {
        var entries: [AccountBalanceModel] = []
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(configuration.account!.identifier!)")!
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
                        entries.append(AccountBalanceModel(date: Date(), account: AvailableAccount(id: decodedResponse.data.id, displayName: decodedResponse.data.attributes.displayName, balance: decodedResponse.data.attributes.balance.valueShort)))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                }
            }
        }
        .resume()
    }
}

struct AccountBalanceModel: TimelineEntry {
    let date: Date
    var account: AvailableAccount
}

struct AccountBalanceEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: AccountBalanceProvider.Entry

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                if family != .systemSmall {
                    Text("Account Balance")
                        .font(.custom("CircularStd-Bold", size: 23))
                        .foregroundColor(Color("AccentColour"))
                    Spacer()
                }
                Text(entry.account.balance)
                    .font(.custom("CircularStd-Bold", size: 23))
                    .foregroundColor(family != .systemSmall ? .primary : Color("AccentColour"))
                Text(entry.account.displayName)
                    .font(.custom("CircularStd-Book", size: 17))
                    .foregroundColor(.primary)
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
        .description("Displays the balance of an account of your choosing.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
