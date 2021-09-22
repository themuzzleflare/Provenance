import WidgetKit

struct AccountBalanceProvider: IntentTimelineProvider {
  typealias Entry = AccountBalanceEntry
  typealias Intent = AccountSelectionIntent
  
  func placeholder(in context: Context) -> Entry {
    return .placeholder
  }
  
  func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
    completion(.placeholder)
  }
  
  func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    guard let accountId = configuration.account?.identifier ?? appDefaults.selectedAccount else {
      let timeline = Timeline(entries: .singleEntry(with: .empty), policy: .atEnd)
      completion(timeline)
      return
    }
    UpFacade.retrieveAccount(for: accountId) { (result) in
      switch result {
      case let .success(account):
        appDefaults.selectedAccount = account.id
        let entry = Entry(date: Date(), account: account.accountBalanceModel, error: nil)
        let timeline = Timeline(entries: .singleEntry(with: entry), policy: .atEnd)
        completion(timeline)
      case let .failure(error):
        let entry = Entry(date: Date(), account: nil, error: error)
        let timeline = Timeline(entries: .singleEntry(with: entry), policy: .atEnd)
        completion(timeline)
      }
    }
  }
}
