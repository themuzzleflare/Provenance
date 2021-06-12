import SwiftUI
import WidgetKit

struct LatestTransactionProvider: IntentTimelineProvider {
    typealias Entry = LatestTransactionModel
    typealias Intent = DateStyleSelectionIntent

    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "Officeworks", transactionDate: "21 hours ago", transactionAmount: "-$79.95", error: "")
    }

    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> ()) {
        completion(Entry(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "Officeworks", transactionDate: "21 hours ago", transactionAmount: "-$79.95", error: ""))
    }

    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [Entry] = []
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["page[size]": "1"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer \(appDefaults.apiKey)"
        ]
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    var creationDate: String {
                        switch configuration.dateStyle {
                            case .unknown:
                                return decodedResponse.data.first!.attributes.creationDate
                            case .absolute:
                                return decodedResponse.data.first!.attributes.creationDateAbsolute
                            case .relative:
                                return decodedResponse.data.first!.attributes.creationDateRelative
                        }
                    }
                    DispatchQueue.main.async {
                        entries.append(Entry(date: Date(), transactionValueInBaseUnits: decodedResponse.data.first!.attributes.amount.valueInBaseUnits.signum(), transactionDescription: decodedResponse.data.first!.attributes.description, transactionDate: creationDate, transactionAmount: decodedResponse.data.first!.attributes.amount.valueShort, error: ""))
                        completion(Timeline(entries: entries, policy: .atEnd))
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        entries.append(Entry(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: decodedResponse.errors.first!.detail))
                        completion(Timeline(entries: entries, policy: .atEnd))
                    }
                } else {
                    DispatchQueue.main.async {
                        entries.append(Entry(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: "JSON Decoding Failed!"))
                        completion(Timeline(entries: entries, policy: .atEnd))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    entries.append(Entry(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: error?.localizedDescription ?? "Unknown Error!"))
                    completion(Timeline(entries: entries, policy: .atEnd))
                }
            }
        }
        .resume()
    }
}

struct LatestTransactionModel: TimelineEntry {
    let date: Date
    var transactionValueInBaseUnits: Int64
    var transactionDescription: String
    var transactionDate: String
    var transactionAmount: String
    var error: String
}

struct LatestTransactionEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: LatestTransactionProvider.Entry

    @ViewBuilder
    var body: some View {
        ZStack {
            VStack {
                if entry.error.isEmpty && family != .systemSmall {
                    Text("Latest Transaction")
                        .font(.custom("CircularStd-Bold", size: 23))
                        .foregroundColor(Color("AccentColour"))
                    Spacer()
                }
                if family != .systemSmall {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.transactionDescription)
                                .font(.custom("CircularStd-Bold", size: 17))
                                .foregroundColor(.primary)
                            Text(entry.transactionDate)
                                .font(.custom("CircularStd-BookItalic", size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(entry.transactionAmount)
                            .foregroundColor(entry.transactionValueInBaseUnits == -1 ? .primary : Color("greenColour"))
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Text(entry.transactionDescription)
                        .font(.custom("CircularStd-Bold", size: 17))
                        .foregroundColor(Color("AccentColour"))
                    Text(entry.transactionAmount)
                        .foregroundColor(entry.transactionValueInBaseUnits == -1 ? .primary : Color("greenColour"))
                        .font(.custom("CircularStd-Book", size: 14))
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    Text(entry.transactionDate)
                        .font(.custom("CircularStd-BookItalic", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .overlay(Group {
            if !entry.error.isEmpty {
                switch family {
                    case .systemSmall:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    default:
                        Text(entry.error)
                            .padding()
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.custom("CircularStd-Book", size: 14))
                            .foregroundColor(.secondary)
                }
            }
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("WidgetBackground"))
    }
}

struct LatestTransaction: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: "latestTransactionWidget", intent: DateStyleSelectionIntent.self, provider: LatestTransactionProvider()) { entry in
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
        ForEach(families, id: \.self) { family in
            LatestTransactionEntryView(entry: LatestTransactionModel(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "Officeworks", transactionDate: "21 hours ago", transactionAmount: "-$79.95", error: ""))
                .previewDisplayName(family.description)
                .previewContext(WidgetPreviewContext(family: family))
                .colorScheme(.dark)
        }
    }
}
