import WidgetKit

struct LatestTransactionProvider: IntentTimelineProvider {
  typealias Entry = LatestTransactionEntry
  typealias Intent = DateStyleSelectionIntent

  func placeholder(in context: Context) -> Entry {
    return .placeholder
  }

  func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
    completion(.placeholder)
  }

  func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    UpFacade.retrieveLatestTransaction { (result) in
      switch result {
      case let .success(transactions):
        let entry = Entry(date: Date(), transaction: transactions[0].latestTransactionModel(configuration: configuration), error: nil)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      case let .failure(error):
        let entry = Entry(date: Date(), transaction: nil, error: error)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }
  }
}
