import Intents
import SwiftDate
import Alamofire
import SwiftyJSON

final class IntentHandler: INExtension {
  override func handler(for intent: INIntent) -> Any {
    return self
  }
}

extension IntentHandler: AccountSelectionIntentHandling {
  func provideAccountOptionsCollection(for intent: AccountSelectionIntent, with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {
    UpFacade.listAccounts { (result) in
      switch result {
      case let .success(accounts):
        let collection = INObjectCollection(items: accounts.accountTypes)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }
}

extension IntentHandler: ListTransactionsIntentHandling {
  func resolveSince(for intent: ListTransactionsIntent, with completion: @escaping (ListTransactionsSinceResolutionResult) -> Void) {
    SwiftDate.defaultRegion = .current
    if let since = intent.since, let date = since.date {
      if date.isInFuture {
        completion(.unsupported(forReason: .dateInFuture))
      } else {
        completion(.success(with: since))
      }
    } else {
      completion(.notRequired())
    }
  }

  func provideAccountOptionsCollection(for intent: ListTransactionsIntent, with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {
    UpFacade.listAccounts { (result) in
      switch result {
      case let .success(accounts):
        let collection = INObjectCollection(items: accounts.accountTypes)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func provideCategoryOptionsCollection(for intent: ListTransactionsIntent, with completion: @escaping (INObjectCollection<CategoryType>?, Error?) -> Void) {
    UpFacade.listCategories { (result) in
      switch result {
      case let .success(categories):
        let collection = INObjectCollection(items: categories.categoryTypes)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func provideTagOptionsCollection(for intent: ListTransactionsIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    UpFacade.listTags { (result) in
      switch result {
      case let .success(tags):
        let collection = INObjectCollection(items: tags.stringArray)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func handle(intent: ListTransactionsIntent, completion: @escaping (ListTransactionsIntentResponse) -> Void) {
    SwiftDate.defaultRegion = .current

    var requestUrl = String()

    var headers: HTTPHeaders = [
      .accept("application/json")
    ]

    var queryParameters: Parameters = [
      "page[size]": "100"
    ]

    if let apiKey = intent.apiKey {
      headers.add(.authorization(bearerToken: apiKey.isEmpty ? appDefaults.apiKey : apiKey))
    } else {
      headers.add(.authorization(bearerToken: appDefaults.apiKey))
    }

    if let account = intent.account?.identifier {
      requestUrl = "https://api.up.com.au/api/v1/accounts/\(account)/transactions"
    } else {
      requestUrl = "https://api.up.com.au/api/v1/transactions"
    }

    var filterStatus: String? {
      switch intent.status {
      case .held:
        return "HELD"
      case .settled:
        return "SETTLED"
      case .unknown, .all:
        return nil
      }
    }

    var filterSince: String? {
      return intent.since?.date?.toISO()
    }

    var filterUntil: String? {
      return intent.until?.date?.toISO()
    }

    if let status = filterStatus {
      queryParameters.updateValue(status, forKey: "filter[status]")
    }

    if let since = filterSince {
      queryParameters.updateValue(since, forKey: "filter[since]")
    }

    if let until = filterUntil {
      queryParameters.updateValue(until, forKey: "filter[until]")
    }

    if let category = intent.category?.identifier {
      queryParameters.updateValue(category, forKey: "filter[category]")
    }

    if let tag = intent.tag {
      queryParameters.updateValue(tag, forKey: "filter[tag]")
    }

    AF.request(requestUrl, method: .get, parameters: queryParameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          if transactions.data.isEmpty {
            completion(ListTransactionsIntentResponse(code: .noContent, userActivity: nil))
          } else {
            completion(transactions.listTransactionsIntentResponse)
          }
        case let .failure(error):
          completion(.failure(error: error.localizedDescription))
        }
      }
  }
}

extension IntentHandler: AddTagToTransactionIntentHandling {
  func provideTransactionOptionsCollection(for intent: AddTagToTransactionIntent, with completion: @escaping (INObjectCollection<TransactionType>?, Error?) -> Void) {
    UpFacade.listTransactions { (result) in
      switch result {
      case let .success(transactions):
        let collection = INObjectCollection(items: transactions.transactionTypes)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func provideTagsOptionsCollection(for intent: AddTagToTransactionIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    UpFacade.listTags { (result) in
      switch result {
      case let .success(tags):
        let collection = INObjectCollection(items: tags.stringArray)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func resolveTransaction(for intent: AddTagToTransactionIntent, with completion: @escaping (TransactionTypeResolutionResult) -> Void) {
    if let transaction = intent.transaction {
      completion(.success(with: transaction))
    } else {
      completion(.needsValue())
    }
  }

  func resolveTags(for intent: AddTagToTransactionIntent, with completion: @escaping ([AddTagToTransactionTagsResolutionResult]) -> Void) {
    if let tags = intent.tags {
      if tags.count > 6 {
        completion([.unsupported(forReason: .tooManyTags)])
      } else if tags.isEmpty {
        completion([.needsValue()])
      } else {
        let results = tags.map { AddTagToTransactionTagsResolutionResult.success(with: $0) }
        completion(results)
      }
    } else {
      completion([.needsValue()])
    }
  }

  func handle(intent: AddTagToTransactionIntent, completion: @escaping (AddTagToTransactionIntentResponse) -> Void) {
    guard let transaction = intent.transaction, let transactionIdentifrier = transaction.identifier else {
      completion(.failure(error: "Invalid transaction identifier."))
      return
    }

    guard let tags = intent.tags else {
      completion(.failure(error: "No tags selected."))
      return
    }

    UpFacade.modifyTags(adding: tags, to: transactionIdentifrier) { (error) in
      if let error = error {
        completion(.failure(error: error.description))
      } else {
        completion(.success(tags: tags, transaction: transaction))
      }
    }
  }
}

extension IntentHandler: RemoveTagFromTransactionIntentHandling {
  func provideTransactionOptionsCollection(for intent: RemoveTagFromTransactionIntent, with completion: @escaping (INObjectCollection<TransactionType>?, Error?) -> Void) {
    UpFacade.listTransactions { (result) in
      switch result {
      case let .success(transactions):
        let collection = INObjectCollection(items: transactions.transactionTypes)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func provideTagsOptionsCollection(for intent: RemoveTagFromTransactionIntent, with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    guard let transaction = intent.transaction?.identifier else {
      completion(nil, nil)
      return
    }

    UpFacade.retrieveTransaction(for: transaction) { result in
      switch result {
      case let .success(transaction):
        let collection = INObjectCollection(items: transaction.tagsArray)
        completion(collection, nil)
      case let .failure(error):
        completion(nil, error)
      }
    }
  }

  func resolveTransaction(for intent: RemoveTagFromTransactionIntent, with completion: @escaping (RemoveTagFromTransactionTransactionResolutionResult) -> Void) {
    if let transactionType = intent.transaction, let transactionId = transactionType.identifier {
      UpFacade.retrieveTransaction(for: transactionId) { (result) in
        switch result {
        case let .success(transaction):
          if transaction.relationships.tags.data.isEmpty {
            completion(.unsupported(forReason: .noTags))
          } else {
            completion(.success(with: transactionType))
          }
        case let .failure(error):
          completion(.needsValue())
        }
      }
    } else {
      completion(.needsValue())
    }
  }

  func resolveTags(for intent: RemoveTagFromTransactionIntent, with completion: @escaping ([INStringResolutionResult]) -> Void) {
    if let tags = intent.tags {
      let results = tags.map { INStringResolutionResult.success(with: $0) }
      completion(results)
    } else {
      completion([.needsValue()])
    }
  }

  func handle(intent: RemoveTagFromTransactionIntent, completion: @escaping (RemoveTagFromTransactionIntentResponse) -> Void) {
    guard let transaction = intent.transaction, let transactionIdentifier = transaction.identifier else {
      completion(.failure(error: "Invalid transaction identifier."))
      return
    }

    guard let tags = intent.tags else {
      completion(.failure(error: "No tags selected."))
      return
    }

    UpFacade.modifyTags(removing: tags, from: transactionIdentifier) { (error) in
      if let error = error {
        completion(.failure(error: error.description))
      } else {
        completion(.success(tags: tags, transaction: transaction))
      }
    }
  }
}

extension Array where Element: AccountResource {
  var accountTypes: [AccountType] {
    return self.map { (account) in
      AccountType(identifier: account.id, display: account.attributes.displayName, subtitle: account.attributes.balance.valueShort, image: nil)
    }
  }
}

extension Array where Element: TagResource {
  var stringArray: [NSString] {
    return self.map { (tag) in
      NSString(string: tag.id)
    }
  }
}

extension Array where Element: CategoryResource {
  var categoryTypes: [CategoryType] {
    return self.map { (category) in
      CategoryType(identifier: category.id, display: category.attributes.name)
    }
  }
}

extension Array where Element: TransactionResource {
  var transactionTypes: [TransactionType] {
    return self.map { (transaction) in
      let transactionResponse = TransactionType(identifier: transaction.id, display: transaction.attributes.description, subtitle: transaction.attributes.amount.valueShort, image: nil)
      transactionResponse.transactionDescription = transaction.attributes.description
      transactionResponse.transactionCreationDate = transaction.attributes.creationDate
      transactionResponse.transactionAmount = transaction.attributes.amount.valueShort
      return transactionResponse
    }
  }
}

extension Transaction {
  var listTransactionsIntentResponse: ListTransactionsIntentResponse {
    let transactionsResponse = ListTransactionsIntentResponse.success(transactionsCount: NSNumber(value: self.data.count))
    transactionsResponse.transactions = self.data.transactionTypes
    return transactionsResponse
  }
}

extension TransactionResource {
  var tagsArray: [NSString] {
    return self.relationships.tags.data.map { (tag) in
      NSString(string: tag.id)
    }
  }
}
