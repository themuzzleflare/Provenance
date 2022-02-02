import Foundation
import Alamofire

typealias Up = UpFacade

enum UpFacade {
  private static let baseUrl = "https://api.up.com.au/api/v1"
  private static let delegate = UpDelegate()
  private static let interceptor = UpInterceptor()
  private static let eventMonitor = UpEventMonitor()
  private static let session = Session(delegate: delegate, interceptor: interceptor, eventMonitors: [eventMonitor])
  private static let validation: DataRequest.Validation = { (_, response, data) in
    if let data = data, let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data), let firstError = errorResponse.errors.first {
      let error = UpError(statusCode: response.statusCode, detail: firstError.detail)
      return .failure(error)
    }
    return .success(())
  }

  /// Ping
  ///
  /// - Parameters:
  ///   - key: The personal access token to ping with.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Make a basic ping request to the API.
  /// This is useful to verify that authentication is functioning correctly.
  /// On authentication success an HTTP `200` status is returned.
  /// On failure an HTTP `401` error response is returned.

  static func ping(with key: String, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .authorization(bearerToken: key)
    ]

    session.request("\(baseUrl)/util/ping",
                    headers: headers)
      .validate(validation)
      .response { (response) in
        completion(response.error)
      }
  }

  /// List transactions
  ///
  /// - Parameters:
  ///   - cursor: The pagination cursor to apply to the request.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all transactions across all accounts for the currently authenticated user.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listTransactions(cursor: String? = nil,
                               completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    var parameters: Parameters = [
      ParamKeys.pageSize: "20"
    ]

    if let cursor = cursor {
      parameters.updateValue(cursor, forKey: ParamKeys.pageAfter)
    }

    session.request("\(baseUrl)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          Store.provenance.paginationCursor = transactions.links.nextCursor ?? ""
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// List complete transactions
  ///
  /// - Parameters:
  ///   - cursor: The pagination cursor to apply to the request.
  ///   - inputTransactions: An array of `TransactionResource` objects to prepend to the response.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all transactions across all accounts for the currently authenticated user.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listCompleteTransactions(cursor: String? = nil,
                                       inputTransactions: [TransactionResource] = [],
                                       completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    var parameters: Parameters = [
      ParamKeys.pageSize: "100"
    ]

    if let cursor = cursor {
      parameters.updateValue(cursor, forKey: ParamKeys.pageAfter)
    }

    session.request("\(baseUrl)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          if let nextCursor = transactions.links.nextCursor {
            listCompleteTransactions(
              cursor: nextCursor,
              inputTransactions: (inputTransactions + transactions.data),
              completion: completion
            )
          } else {
            completion(.success(inputTransactions + transactions.data))
          }
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// List transactions by account
  ///
  /// - Parameters:
  ///   - account: The account to list transactions for.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all transactions for a specific account.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listTransactions(filterBy account: AccountResource,
                               completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.pageSize: "100"
    ]

    session.request("\(baseUrl)/accounts/\(account.id)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// List transactions by tag
  ///
  /// - Parameters:
  ///   - tag: The tag to list transactions for.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all transactions for a specific tag.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listTransactions(filterBy tag: TagResource,
                               completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.filterTag: tag.id,
      ParamKeys.pageSize: "100"
    ]

    session.request("\(baseUrl)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// List transactions by category
  ///
  /// - Parameters:
  ///   - category: The category to list transactions for.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all transactions for a specific category.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listTransactions(filterBy category: CategoryResource,
                               completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.filterCategory: category.id,
      ParamKeys.pageSize: "100"
    ]

    session.request("\(baseUrl)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve latest transaction
  ///
  /// - Parameter completion: Block to execute for handling the request response.
  ///
  /// Retrieve the latest transaction across all accounts.

  static func retrieveLatestTransaction(completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.pageSize: "1"
    ]

    session.request("\(baseUrl)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          if let transaction = transactions.data.first {
            completion(.success(transaction))
          } else {
            completion(.failure(.responseValidationFailed(reason: .dataFileNil)))
          }
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve latest transaction for account
  ///
  /// - Parameters:
  ///   - account: The account to retrieve the latest transaction for.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve the latest transaction for a specific account.

  static func retrieveLatestTransaction(for account: AccountResource,
                                        completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.pageSize: "1"
    ]

    session.request("\(baseUrl)/accounts/\(account.id)/transactions",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TransactionsResponse.self) { (response) in
        switch response.result {
        case let .success(transactions):
          if let transaction = transactions.data.first {
            completion(.success(transaction))
          } else {
            completion(.failure(.responseValidationFailed(reason: .dataFileNil)))
          }
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve transaction
  ///
  /// - Parameters:
  ///   - transactionId: The unique identifier for the transaction to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific transaction by providing its unique identifier.

  static func retrieveTransaction(for transactionId: String,
                                  completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    session.request("\(baseUrl)/transactions/\(transactionId)")
      .validate(validation)
      .responseDecodable(of: TransactionResponse.self) { (response) in
        switch response.result {
        case let .success(transaction):
          completion(.success(transaction.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve transaction
  ///
  /// - Parameters:
  ///   - transaction: The transaction to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific transaction by providing its unique identifier.

  static func retrieveTransaction(for transaction: TransactionResource,
                                  completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    retrieveTransaction(for: transaction.id, completion: completion)
  }

  /// List accounts
  ///
  /// - Parameter completion: Block to execute for handling the request response.
  ///
  /// Retrieve a paginated list of all accounts for the currently authenticated user.
  /// The returned list is paginated and can be scrolled by following the `prev` and `next` links where present.

  static func listAccounts(completion: @escaping (Result<[AccountResource], AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.pageSize: "100"
    ]

    session.request("\(baseUrl)/accounts",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: AccountsResponse.self) { (response) in
        switch response.result {
        case let .success(accounts):
          completion(.success(accounts.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve account
  ///
  /// - Parameters:
  ///   - accountId: The unique identifier for the account to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific account by providing its unique identifier.

  static func retrieveAccount(for accountId: String,
                              completion: @escaping (Result<AccountResource, AFError>) -> Void) {
    session.request("\(baseUrl)/accounts/\(accountId)")
      .validate(validation)
      .responseDecodable(of: AccountResponse.self) { (response) in
        switch response.result {
        case let .success(account):
          completion(.success(account.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve account
  ///
  /// - Parameters:
  ///   - account: The account to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific account by providing its unique identifier.

  static func retrieveAccount(for account: AccountResource,
                              completion: @escaping (Result<AccountResource, AFError>) -> Void) {
    retrieveAccount(for: account.id, completion: completion)
  }

  /// List tags
  ///
  /// - Parameter completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all tags currently in use.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// Results are ordered lexicographically.
  /// The `transactions` relationship for each tag exposes a link to get the transactions with the given tag.

  static func listTags(completion: @escaping (Result<[TagResource], AFError>) -> Void) {
    let parameters: Parameters = [
      ParamKeys.pageSize: "100"
    ]

    session.request("\(baseUrl)/tags",
                    parameters: parameters)
      .validate(validation)
      .responseDecodable(of: TagsResponse.self) { (response) in
        switch response.result {
        case let .success(tags):
          completion(.success(tags.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Add tags to transaction
  ///
  /// - Parameters:
  ///   - tags: The tags to add.
  ///   - transaction: The transaction to add the tags to.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Associates one or more tags with a specific transaction.
  /// No more than 6 tags may be present on any single transaction.
  /// Duplicate tags are silently ignored.
  /// An HTTP `204` is returned on success.
  /// The associated tags, along with this request URL, are also exposed via the `tags` relationship on the transaction resource returned from `/transactions/{id}`.

  static func modifyTags(adding tags: [TagResource],
                         to transaction: String,
                         completion: @escaping (AFError?) -> Void) {
    session.request("\(baseUrl)/transactions/\(transaction)/relationships/tags",
                    method: .post,
                    parameters: ModifyTags(tags: tags),
                    encoder: .json)
      .validate(validation)
      .response { (response) in
        completion(response.error)
      }
  }

  /// Add tags to transaction
  ///
  /// - Parameters:
  ///   - tags: The tags to add.
  ///   - transaction: The transaction to add the tags to.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Associates one or more tags with a specific transaction.
  /// No more than 6 tags may be present on any single transaction.
  /// Duplicate tags are silently ignored.
  /// An HTTP `204` is returned on success.
  /// The associated tags, along with this request URL, are also exposed via the `tags` relationship on the transaction resource returned from `/transactions/{id}`.

  static func modifyTags(adding tags: [TagResource],
                         to transaction: TransactionResource,
                         completion: @escaping (AFError?) -> Void) {
    modifyTags(adding: tags, to: transaction.id, completion: completion)
  }

  /// Remove tags from transaction
  ///
  /// - Parameters:
  ///   - tags: The tags to remove.
  ///   - transaction: The transaction to remove the tags from.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Disassociates one or more tags from a specific transaction.
  /// Tags that are not associated are silently ignored.
  /// An HTTP `204` is returned on success.
  /// The associated tags, along with this request URL, are also exposed via the `tags` relationship on the transaction resource returned from `/transactions/{id}`.

  static func modifyTags(removing tags: [TagResource],
                         from transaction: String,
                         completion: @escaping (AFError?) -> Void) {
    session.request("\(baseUrl)/transactions/\(transaction)/relationships/tags",
                    method: .delete,
                    parameters: ModifyTags(tags: tags),
                    encoder: .json)
      .validate(validation)
      .response { (response) in
        completion(response.error)
      }
  }

  /// Remove tags from transaction
  ///
  /// - Parameters:
  ///   - tags: The tags to remove.
  ///   - transaction: The transaction to remove the tags from.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Disassociates one or more tags from a specific transaction.
  /// Tags that are not associated are silently ignored.
  /// An HTTP `204` is returned on success.
  /// The associated tags, along with this request URL, are also exposed via the `tags` relationship on the transaction resource returned from `/transactions/{id}`.

  static func modifyTags(removing tags: [TagResource],
                         from transaction: TransactionResource,
                         completion: @escaping (AFError?) -> Void) {
    modifyTags(removing: tags, from: transaction.id, completion: completion)
  }

  /// List categories
  ///
  /// - Parameter completion: Block to execute for handling the request response.
  ///
  /// Retrieve a list of all categories and their ancestry. The returned list is not paginated.

  static func listCategories(completion: @escaping (Result<[CategoryResource], AFError>) -> Void) {
    session.request("\(baseUrl)/categories")
      .validate(validation)
      .responseDecodable(of: CategoriesResponse.self) { (response) in
        switch response.result {
        case let .success(categories):
          completion(.success(categories.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve category
  ///
  /// - Parameters:
  ///   - categoryId: The unique identifier for the category to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific category by providing its unique identifier.

  static func retrieveCategory(for categoryId: String,
                               completion: @escaping (Result<CategoryResource, AFError>) -> Void) {
    session.request("\(baseUrl)/categories/\(categoryId)")
      .validate(validation)
      .responseDecodable(of: CategoryResponse.self) { (response) in
        switch response.result {
        case let .success(category):
          completion(.success(category.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }

  /// Retrieve category
  ///
  /// - Parameters:
  ///   - category: The category to retrieve.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Retrieve a specific category by providing its unique identifier.

  static func retrieveCategory(for category: CategoryResource,
                               completion: @escaping (Result<CategoryResource, AFError>) -> Void) {
    retrieveCategory(for: category.id, completion: completion)
  }

  /// Categorize transaction
  ///
  /// - Parameters:
  ///   - transaction: The transaction to categorise.
  ///   - category: The category to apply to the operation.
  ///   - completion: Block to execute for handling the request response.
  ///
  /// Updates the category associated with a transaction.
  /// Only transactions for which `isCategorizable` is set to true support this operation.
  /// The `id` is taken from the list exposed on `/categories` and cannot be one of the top-level (parent) categories.
  /// To de-categorize a transaction, set the entire `data` key to `null`.
  /// An HTTP `204` is returned on success.
  /// The associated category, along with its request URL is also exposed via the `category` relationship on the transaction resource returned from `/transactions/{id}`.

  static func categorise(transaction: TransactionResource,
                         category: CategoryResource? = nil,
                         completion: @escaping (AFError?) -> Void) {
    session.request("\(baseUrl)/transactions/\(transaction.id)/relationships/category",
                    method: .patch,
                    parameters: ModifyCategories(category: category),
                    encoder: .json)
      .validate(validation)
      .response { (response) in
        completion(response.error)
      }
  }
}

// MARK: - Concurrency

#if compiler(>=5.5.2) && canImport(_Concurrency)

extension UpFacade {
  /// List transactions
  ///
  /// - Parameter cursor: The pagination cursor to apply to the request.
  ///
  /// Retrieve a list of all transactions across all accounts for the currently authenticated user.
  /// The returned list is [paginated](https://developer.up.com.au/#pagination) and can be scrolled by following the `next` and `prev` links where present.
  /// To narrow the results to a specific date range pass one or both of `filter[since]` and `filter[until]` in the query string.
  /// These filter parameters **should not** be used for pagination.
  /// Results are ordered newest first to oldest last.

  static func listTransactions(cursor: String? = nil) async throws -> [TransactionResource] {
    var parameters: Parameters = [
      ParamKeys.pageSize: "20"
    ]

    if let cursor = cursor {
      parameters.updateValue(cursor, forKey: ParamKeys.pageAfter)
    }

    let response = try await session.request("\(baseUrl)/transactions",
                                             parameters: parameters)
      .validate(validation)
      .serializingDecodable(TransactionsResponse.self).value

    Store.provenance.paginationCursor = response.links.nextCursor ?? ""

    return response.data
  }
}

#endif

// MARK: -

extension UpFacade {
  enum ParamKeys {
    /// The number of records to return in each page.
    static let pageSize = "page[size]"

    /// The transaction status for which to return records.
    /// This can be used to filter `HELD` transactions from those that are `SETTLED`.
    static let filterStatus = "filter[status]"

    /// The start date-time from which to return records, formatted according to rfc-3339.
    /// Not to be used for pagination purposes.
    static let filterSince = "filter[since]"

    /// The end date-time up to which to return records, formatted according to rfc-3339.
    /// Not to be used for pagination purposes.
    static let filterUntil = "filter[until]"

    /// The category identifier for which to filter transactions.
    /// Both parent and child categories can be filtered through this parameter.
    /// Providing an invalid category identifier results in a `404` response.
    static let filterCategory = "filter[category]"

    /// The unique identifier of a parent category for which to return only its children.
    /// Providing an invalid category identifier results in a `404` response.
    static let filterParent = "filter[parent]"

    /// A transaction tag to filter for which to return records.
    /// If the tag does not exist, zero records are returned and a success response is given.
    static let filterTag = "filter[tag]"

    /// The type of account for which to return records.
    /// This can be used to filter Savers from spending accounts.
    static let filterAccountType = "filter[accountType]"

    /// The account ownership structure for which to return records.
    /// This can be used to filter 2Up accounts from Up accounts.
    static let filterOwnershipType = "filter[ownershipType]"

    static let pageBefore = "page[before]"

    static let pageAfter = "page[after]"
  }
}
