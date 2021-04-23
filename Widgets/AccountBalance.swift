import SwiftUI
import WidgetKit

struct AccountBalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> AccountBalanceModel {
        AccountBalanceModel(date: Date(), accountDisplayName: "Up Account", accountBalance: "$123.45", error: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AccountBalanceModel) -> ()) {
        let entry = AccountBalanceModel(date: Date(), accountDisplayName: "Up Account", accountBalance: "$123.45", error: "")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [AccountBalanceModel] = []
        var url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        let urlParams = ["page[size]":"1"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.apiKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        entries.append(AccountBalanceModel(date: Date(), accountDisplayName: decodedResponse.data.first!.attributes.displayName, accountBalance: decodedResponse.data.first!.attributes.balance.valueShort, error: ""))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        entries.append(AccountBalanceModel(date: Date(), accountDisplayName: "", accountBalance: "", error: decodedResponse.errors.first!.detail))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                } else {
                    DispatchQueue.main.async {
                        entries.append(AccountBalanceModel(date: Date(), accountDisplayName: "", accountBalance: "", error: "JSON Decoding Failed!"))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    entries.append(AccountBalanceModel(date: Date(), accountDisplayName: "", accountBalance: "", error: error?.localizedDescription ?? "Unknown Error!"))
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                }
            }
        }
        .resume()
    }
}

struct AccountBalanceModel: TimelineEntry {
    let date: Date
    var accountDisplayName: String
    var accountBalance: String
    var error: String
}

struct AccountBalanceEntryView: View {
    @Environment(\.widgetFamily) private var family
    
    var entry: AccountBalanceModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 0) {
                if entry.error.isEmpty && family != .systemSmall {
                    Text("Account Balance")
                        .font(.custom("CircularStd-Bold", size: 23))
                        .foregroundColor(Color("AccentColour"))
                    Spacer()
                }
                Text(entry.accountBalance)
                    .font(.custom("CircularStd-Bold", size: 23))
                    .foregroundColor(family != .systemSmall ? .primary : Color("AccentColour"))
                Text(entry.accountDisplayName)
                    .font(.custom("CircularStd-Book", size: 17))
                    .foregroundColor(.primary)
            }
            .padding()
        }
        .overlay(Group {
            Text(entry.error)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("CircularStd-Book", size: 17))
                .foregroundColor(.primary)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("WidgetBackground"))
    }
}

struct AccountBalance: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "cloud.tavitian.provenance.widgets.account-balance", provider: AccountBalanceProvider()) { entry in
            AccountBalanceEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Account Balance")
        .description("Displays the account balance of the main transactional Up account.")
    }
}

struct AccountBalance_Previews: PreviewProvider {
    static let families: [WidgetFamily] = [.systemSmall, .systemMedium]
    static var previews: some View {
        ForEach(families, id: \.self) { family in
            AccountBalanceEntryView(entry: AccountBalanceModel(date: Date(), accountDisplayName: "Up Account", accountBalance: "$123.45", error: ""))
                .previewContext(WidgetPreviewContext(family: family))
                .previewDisplayName(family.description)
                .colorScheme(.dark)
        }
    }
}
