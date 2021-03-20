import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Model {
        Model(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "Officeworks", transactionDate: "21 hours ago", transactionAmount: "-$79.95", error: "")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Model) -> ()) {
        let entry = Model(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "Officeworks", transactionDate: "21 hours ago", transactionAmount: "-$79.95", error: "")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [Model] = []
        
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        entries.append(.init(date: Date(), transactionValueInBaseUnits: decodedResponse.data.first!.attributes.amount.valueInBaseUnits.signum(), transactionDescription: decodedResponse.data.first!.attributes.description, transactionDate: decodedResponse.data.first!.attributes.creationDate, transactionAmount: decodedResponse.data.first!.attributes.amount.valueShort, error: ""))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        entries.append(.init(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: decodedResponse.errors.first!.detail))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                } else {
                    DispatchQueue.main.async {
                        entries.append(.init(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: "JSON Decoding Failed!"))
                        let timeline = Timeline(entries: entries, policy: .atEnd)
                        completion(timeline)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    entries.append(.init(date: Date(), transactionValueInBaseUnits: -1, transactionDescription: "", transactionDate: "", transactionAmount: "", error: error?.localizedDescription ?? "Unknown Error!"))
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                }
            }
        }
        .resume()
    }
}

struct Model: TimelineEntry {
    let date: Date
    var transactionValueInBaseUnits: Int64
    var transactionDescription: String
    var transactionDate: String
    var transactionAmount: String
    var error: String
}

struct LatestTransactionEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                if entry.error.isEmpty && family != .systemSmall {
                    Text("Latest Transaction")
                        .font(.custom("CircularStd-Bold", size: 23))
                        .foregroundColor(Color("AccentColor"))
                    Spacer()
                }
                if family != .systemSmall {
                    HStack(alignment: .center, spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(entry.transactionDescription)
                                .font(.custom("CircularStd-Bold", size: 17))
                            Text(entry.transactionDate)
                                .font(.custom("CircularStd-Book", size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(entry.transactionAmount)
                            .foregroundColor(entry.transactionValueInBaseUnits == -1 ? .white : Color("greenColour"))
                            .font(.custom("CircularStd-Book", size: 17))
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    Text(entry.transactionDescription)
                        .font(.custom("CircularStd-Bold", size: 17))
                        .foregroundColor(Color("AccentColor"))
                    Text(entry.transactionAmount)
                        .foregroundColor(entry.transactionValueInBaseUnits == -1 ? .white : Color("greenColour"))
                        .font(.custom("CircularStd-Book", size: 14))
                        .multilineTextAlignment(.trailing)
                    Spacer()
                    Text(entry.transactionDate)
                        .font(.custom("CircularStd-Book", size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .overlay(Group {
            Text(entry.error)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("CircularStd-Book", size: 17))
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bgColour"))
    }
}

struct LatestTransaction: Widget {
    let kind: String = "LatestTransaction"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LatestTransactionEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Latest Transaction")
        .description("Displays the latest transaction.")
    }
}
