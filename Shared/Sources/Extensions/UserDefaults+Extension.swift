import Foundation
import WidgetKit

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

typealias Store = UserDefaults

extension UserDefaults {
  static let provenance = UserDefaults(suiteName: "group.cloud.tavitian.provenance") ?? .standard

  /// The string of the "apiKey" key.
  @objc dynamic var apiKey: String {
    get {
      return getString(forKey: .apiKey) ?? ""
    }
    set {
      setStore(newValue, forKey: .apiKey)
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  /// The integer of the "dateStyle" key.
  @objc dynamic var dateStyle: Int {
    get {
      return getInteger(forKey: .dateStyle)
    }
    set {
      setStore(newValue, forKey: .dateStyle)
      WidgetCenter.shared.reloadTimelines(ofKind: Widgets.latestTransaction.kind)
      if let dateStyleEnum = AppDateStyle(rawValue: dateStyle) {
        updateAnalyticsProperty(dateStyleEnum.description, forName: .dateStyle)
      }
    }
  }

  /// The integer of the "accountFilter" key.
  @objc dynamic var accountFilter: Int {
    get {
      return getInteger(forKey: .accountFilter)
    }
    set {
      setStore(newValue, forKey: .accountFilter)
      if let filterEnum = AccountTypeOptionEnum(rawValue: accountFilter) {
        updateAnalyticsProperty(filterEnum.description, forName: .accountFilter)
      }
    }
  }

  /// The integer of the "categoryFilter" key.
  @objc dynamic var categoryFilter: Int {
    get {
      return getInteger(forKey: .categoryFilter)
    }
    set {
      setStore(newValue, forKey: .categoryFilter)
      if let filterEnum = CategoryTypeEnum(rawValue: categoryFilter) {
        updateAnalyticsProperty(filterEnum.description, forName: .categoryFilter)
      }
    }
  }

  /// The boolean of the "settledOnly" key.
  @objc dynamic var settledOnly: Bool {
    get {
      return getBool(forKey: .settledOnly)
    }
    set {
      setStore(newValue, forKey: .settledOnly)
      updateAnalyticsProperty(settledOnly.description, forName: .settledOnly)
    }
  }

  /// The integer of the "transactionGrouping" key.
  @objc dynamic var transactionGrouping: Int {
    get {
      return getInteger(forKey: .transactionGrouping)
    }
    set {
      setStore(newValue, forKey: .transactionGrouping)
      if let groupingEnum = TransactionGroupingEnum(rawValue: transactionGrouping) {
        updateAnalyticsProperty(groupingEnum.description, forName: .transactionGrouping)
      }
    }
  }

  @objc dynamic var paginationCursor: String {
    get {
      return getString(forKey: .paginationCursor) ?? ""
    }
    set {
      setStore(newValue, forKey: .paginationCursor)
    }
  }

  /// The last selected account for the account balance widget.
  var selectedAccount: String? {
    get {
      return getString(forKey: .selectedAccount)
    }
    set {
      setStore(newValue, forKey: .selectedAccount)
    }
  }

  var selectedCategory: String {
    get {
      return getString(forKey: .selectedCategory) ?? TransactionCategory.all.rawValue
    }
    set {
      setStore(newValue, forKey: .selectedCategory)
    }
  }

  var appSelectedCategory: TransactionCategory {
    get {
      return TransactionCategory(rawValue: selectedCategory) ?? .all
    }
    set {
      selectedCategory = newValue.rawValue
    }
  }

  /// The configured `AppDateStyle` enumeration based on the integer of the "dateStyle" key.
  var appDateStyle: AppDateStyle {
    get {
      return AppDateStyle(rawValue: dateStyle) ?? .absolute
    }
    set {
      dateStyle = newValue.rawValue
    }
  }

  /// The configured `AccountTypeOptionEnum` enumeration based on the integer of the "accountFilter" key.
  var appAccountFilter: AccountTypeOptionEnum {
    get {
      return AccountTypeOptionEnum(rawValue: accountFilter) ?? .transactional
    }
    set {
      accountFilter = newValue.rawValue
    }
  }

  /// The configured `CategoryTypeEnum` enumeration based on the integer of the "categoryFilter" key.
  var appCategoryFilter: CategoryTypeEnum {
    get {
      return CategoryTypeEnum(rawValue: categoryFilter) ?? .parent
    }
    set {
      categoryFilter = newValue.rawValue
    }
  }

  /// The configured `TransactionGroupingEnum` enumeration based on the integer of the "transactionGrouping" key.
  var appTransactionGrouping: TransactionGroupingEnum {
    get {
      return TransactionGroupingEnum(rawValue: transactionGrouping) ?? .all
    }
    set {
      transactionGrouping = newValue.rawValue
    }
  }

  /// The short version string of the application.
  var appVersion: String {
    return getString(forKey: .appVersion) ?? "Unknown"
  }

  /// The build number of the application.
  var appBuild: String {
    return getString(forKey: .appBuild) ?? "Unknown"
  }
}

// MARK: -

extension UserDefaults {
  private func getString(forKey defaultName: StoreKey) -> String? {
    return string(forKey: defaultName.rawValue)
  }

  private func getInteger(forKey defaultName: StoreKey) -> Int {
    return integer(forKey: defaultName.rawValue)
  }

  private func getBool(forKey defaultName: StoreKey) -> Bool {
    return bool(forKey: defaultName.rawValue)
  }

  private func setStore(_ value: Any?, forKey key: StoreKey) {
    setValue(value, forKey: key.rawValue)
  }

  private func updateAnalyticsProperty(_ value: String, forName name: AnalyticsUserProperty) {
#if canImport(FirebaseAnalytics)
    FirebaseAnalytics.Analytics.setUserProperty(value, forName: name.rawValue)
#endif
  }
}

// MARK: -

extension UserDefaults {
  enum StoreKey: String, CaseIterable {
    case apiKey
    case dateStyle
    case accountFilter
    case categoryFilter
    case settledOnly
    case transactionGrouping
    case selectedAccount
    case selectedCategory
    case paginationCursor
    case appVersion
    case appBuild
  }

  private enum AnalyticsUserProperty: String {
    case dateStyle = "date_style"
    case accountFilter = "account_filter"
    case categoryFilter = "category_filter"
    case settledOnly = "settled_only"
    case transactionGrouping = "transaction_grouping"
  }
}
