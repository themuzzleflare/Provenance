import Foundation
import Intents
import SwiftDate
import Alamofire

final class IntentHandler: INExtension {
  override func handler(for intent: INIntent) -> Any {
    return self
  }
}

// MARK: - AccountSelectionIntentHandling

extension IntentHandler: AccountSelectionIntentHandling {
  func provideAccountOptionsCollection(for intent: AccountSelectionIntent,
                                       with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {
    Up.listAccounts { (result) in
      switch result {
      case let .success(accounts):
        completion(accounts.accountTypes.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }
}

// MARK: - ListTransactionsIntentHandling

extension IntentHandler: ListTransactionsIntentHandling {
  func resolveSince(for intent: ListTransactionsIntent,
                    with completion: @escaping (ListTransactionsSinceResolutionResult) -> Void) {
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

  func provideAccountOptionsCollection(for intent: ListTransactionsIntent,
                                       with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {
    Up.listAccounts { (result) in
      switch result {
      case let .success(accounts):
        completion(accounts.accountTypes.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func provideCategoryOptionsCollection(for intent: ListTransactionsIntent,
                                        with completion: @escaping (INObjectCollection<CategoryType>?, Error?) -> Void) {
    Up.listCategories { (result) in
      switch result {
      case let .success(categories):
        completion(categories.categoryTypes.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func provideTagOptionsCollection(for intent: ListTransactionsIntent,
                                   with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    Up.listTags { (result) in
      switch result {
      case let .success(tags):
        completion(tags.nsStringArray.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func handle(intent: ListTransactionsIntent,
              completion: @escaping (ListTransactionsIntentResponse) -> Void) {
    var requestUrl = String()
    var headers: HTTPHeaders = [
      .accept("application/json")
    ]
    var parameters: Parameters = [
      Up.ParamKey.pageSize: "100"
    ]
    if let apiKey = intent.apiKey, !apiKey.isEmpty {
      headers.add(.authorization(bearerToken: apiKey))
    } else {
      headers.add(.authorization(bearerToken: Store.provenance.apiKey))
    }
    if let account = intent.account?.identifier {
      requestUrl = "\(Up.baseUrl)/accounts/\(account)/transactions"
    } else {
      requestUrl = "\(Up.baseUrl)/transactions"
    }
    var filterSince: String? {
      return intent.since?.date?.toISO()
    }
    var filterUntil: String? {
      return intent.until?.date?.toISO()
    }
    if let status = intent.status.transactionStatusEnum?.rawValue {
      parameters.updateValue(status, forKey: Up.ParamKey.filterStatus)
    }
    if let since = filterSince {
      parameters.updateValue(since, forKey: Up.ParamKey.filterSince)
    }
    if let until = filterUntil {
      parameters.updateValue(until, forKey: Up.ParamKey.filterUntil)
    }
    if let category = intent.category?.identifier {
      parameters.updateValue(category, forKey: Up.ParamKey.filterCategory)
    }
    if let tag = intent.tag {
      parameters.updateValue(tag, forKey: Up.ParamKey.filterTag)
    }
    AF.request(requestUrl, parameters: parameters, headers: headers)
      .validate(Up.validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          if transactions.data.isEmpty {
            completion(.failure(code: .noContent))
          } else {
            completion(.success(transactions: transactions.data.transactionTypes, transactionsCount: transactions.data.count.nsNumber))
          }
        case let .failure(error):
          completion(.failure(error: error.underlyingError?.localizedDescription ?? error.localizedDescription))
        }
      }
  }
}

// MARK: - AddTagToTransactionIntentHandling

extension IntentHandler: AddTagToTransactionIntentHandling {
  func provideTransactionOptionsCollection(for intent: AddTagToTransactionIntent,
                                           with completion: @escaping (INObjectCollection<TransactionType>?, Error?) -> Void) {
    Up.listTransactions { (result) in
      switch result {
      case let .success(transactions):
        completion(transactions.transactionTypes.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func provideTagsOptionsCollection(for intent: AddTagToTransactionIntent,
                                    with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    Up.listTags { (result) in
      switch result {
      case let .success(tags):
        completion(tags.nsStringArray.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func resolveTransaction(for intent: AddTagToTransactionIntent,
                          with completion: @escaping (TransactionTypeResolutionResult) -> Void) {
    if let transaction = intent.transaction {
      completion(.success(with: transaction))
    } else {
      completion(.needsValue())
    }
  }

  func resolveTags(for intent: AddTagToTransactionIntent,
                   with completion: @escaping ([AddTagToTransactionTagsResolutionResult]) -> Void) {
    if let tags = intent.tags {
      if tags.count > 6 {
        completion([.unsupported(forReason: .tooManyTags)])
      } else if tags.isEmpty {
        completion([.needsValue()])
      } else {
        completion(tags.addTagToTransactionTagsResolutionResults)
      }
    } else {
      completion([.needsValue()])
    }
  }

  func handle(intent: AddTagToTransactionIntent,
              completion: @escaping (AddTagToTransactionIntentResponse) -> Void) {
    guard let transaction = intent.transaction, let transactionIdentifier = transaction.identifier else {
      completion(.failure(error: "Invalid transaction identifier."))
      return
    }
    guard let tags = intent.tags else {
      completion(.failure(error: "No tags selected."))
      return
    }
    Up.modifyTags(adding: tags.tagResources, to: transactionIdentifier) { (error) in
      if let error = error {
        completion(.failure(error: error.underlyingError?.localizedDescription ?? error.localizedDescription))
      } else {
        completion(.success(tags: tags, transaction: transaction, userActivity: .addedTagsToTransaction))
      }
    }
  }
}

// MARK: - RemoveTagFromTransactionIntentHandling

extension IntentHandler: RemoveTagFromTransactionIntentHandling {
  func provideTransactionOptionsCollection(for intent: RemoveTagFromTransactionIntent,
                                           with completion: @escaping (INObjectCollection<TransactionType>?, Error?) -> Void) {
    Up.listTransactions { (result) in
      switch result {
      case let .success(transactions):
        completion(transactions.transactionTypes.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func provideTagsOptionsCollection(for intent: RemoveTagFromTransactionIntent,
                                    with completion: @escaping (INObjectCollection<NSString>?, Error?) -> Void) {
    guard let transaction = intent.transaction?.identifier else {
      completion(nil, nil)
      return
    }
    Up.retrieveTransaction(for: transaction) { (result) in
      switch result {
      case let .success(transaction):
        completion(transaction.tagsArray.collection, nil)
      case let .failure(error):
        completion(nil, error.underlyingError ?? error)
      }
    }
  }

  func resolveTransaction(for intent: RemoveTagFromTransactionIntent,
                          with completion: @escaping (RemoveTagFromTransactionTransactionResolutionResult) -> Void) {
    if let transactionType = intent.transaction, let transactionId = transactionType.identifier {
      Up.retrieveTransaction(for: transactionId) { (result) in
        switch result {
        case let .success(transaction):
          if transaction.relationships.tags.data.isEmpty {
            completion(.unsupported(forReason: .noTags))
          } else {
            completion(.success(with: transactionType))
          }
        case .failure:
          completion(.needsValue())
        }
      }
    } else {
      completion(.needsValue())
    }
  }

  func resolveTags(for intent: RemoveTagFromTransactionIntent,
                   with completion: @escaping ([INStringResolutionResult]) -> Void) {
    if let tags = intent.tags {
      completion(tags.stringResolutionResults)
    } else {
      completion([.needsValue()])
    }
  }

  func handle(intent: RemoveTagFromTransactionIntent,
              completion: @escaping (RemoveTagFromTransactionIntentResponse) -> Void) {
    guard let transaction = intent.transaction, let transactionIdentifier = transaction.identifier else {
      completion(.failure(error: "Invalid transaction identifier."))
      return
    }
    guard let tags = intent.tags else {
      completion(.failure(error: "No tags selected."))
      return
    }
    Up.modifyTags(removing: tags.tagResources, from: transactionIdentifier) { (error) in
      if let error = error {
        completion(.failure(error: error.underlyingError?.localizedDescription ?? error.localizedDescription))
      } else {
        completion(.success(tags: tags, transaction: transaction))
      }
    }
  }
}
