import Alamofire

struct UpFacade {
  private static let jsonEncoder = JSONParameterEncoder.default
  
    /// Ping
    ///
    /// - Parameters:
    ///   - key: The API key to ping with.
    ///   - completion: Block to execute for handling the request response.
    ///
    /// Make a basic ping request to the API. This is useful to verify that authentication is functioning correctly. On authentication success an HTTP `200` status is returned. On failure an HTTP `401` error response is returned.
  static func ping(with key: String, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: key)
    ]
    
    AF.request("https://api.up.com.au/api/v1/util/ping", method: .get, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func listTransactions(completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func listTransactions(filterBy account: AccountResource, completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/accounts/\(account.id)/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func listTransactions(filterBy tag: TagResource, completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "filter[tag]": tag.id,
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func listTransactions(filterBy category: CategoryResource, completion: @escaping (Result<[TransactionResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "filter[category]": category.id,
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveLatestTransaction(completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "1"
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data[0]))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveLatestTransaction(for account: AccountResource, completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "1"
    ]
    
    AF.request("https://api.up.com.au/api/v1/accounts/\(account.id)/transactions", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Transaction.self) { (response) in
        switch response.result {
        case let .success(transactions):
          completion(.success(transactions.data[0]))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveTransaction(for transaction: TransactionResource, completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleTransaction.self) { (response) in
        switch response.result {
        case let .success(transaction):
          completion(.success(transaction.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveTransaction(for transactionId: String, completion: @escaping (Result<TransactionResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transactionId)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleTransaction.self) { (response) in
        switch response.result {
        case let .success(transaction):
          completion(.success(transaction.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func listAccounts(completion: @escaping (Result<[AccountResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/accounts", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Account.self) { (response) in
        switch response.result {
        case let .success(accounts):
          completion(.success(accounts.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveAccount(for account: AccountResource, completion: @escaping (Result<AccountResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/accounts/\(account.id)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleAccount.self) { (response) in
        switch response.result {
        case let .success(account):
          completion(.success(account.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveAccount(for accountId: String, completion: @escaping (Result<AccountResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/accounts/\(accountId)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleAccount.self) { (response) in
        switch response.result {
        case let .success(account):
          completion(.success(account.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func listTags(completion: @escaping (Result<[TagResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    let parameters: Parameters = [
      "page[size]": "100"
    ]
    
    AF.request("https://api.up.com.au/api/v1/tags", method: .get, parameters: parameters, headers: headers)
      .validate()
      .responseDecodable(of: Tag.self) { (response) in
        switch response.result {
        case let .success(tags):
          completion(.success(tags.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func modifyTags(adding tags: [TagResource], to transaction: TransactionResource, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags", method: .post, parameters: ModifyTags(tags: tags), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func modifyTags(adding tags: [String], to transaction: String, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction)/relationships/tags", method: .post, parameters: ModifyTags(tags: tags), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func modifyTags(adding tag: TagResource, to transaction: TransactionResource, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags", method: .post, parameters: ModifyTags(tag: tag), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func modifyTags(removing tags: [TagResource], from transaction: TransactionResource, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags", method: .delete, parameters: ModifyTags(tags: tags), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func modifyTags(removing tags: [String], from transaction: String, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction)/relationships/tags", method: .delete, parameters: ModifyTags(tags: tags), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func modifyTags(removing tag: TagResource, from transaction: TransactionResource, completion: @escaping (AFError?) -> Void) {
    let headers: HTTPHeaders = [
      .contentType("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags", method: .delete, parameters: ModifyTags(tag: tag), encoder: jsonEncoder, headers: headers)
      .validate()
      .response { (response) in
        completion(response.error)
      }
  }
  
  static func listCategories(completion: @escaping (Result<[CategoryResource], AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/categories", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: Category.self) { (response) in
        switch response.result {
        case let .success(categories):
          completion(.success(categories.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveCategory(for category: CategoryResource, completion: @escaping (Result<CategoryResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/categories/\(category.id)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleCategory.self) { (response) in
        switch response.result {
        case let .success(category):
          completion(.success(category.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
  
  static func retrieveCategory(for categoryId: String, completion: @escaping (Result<CategoryResource, AFError>) -> Void) {
    let headers: HTTPHeaders = [
      .accept("application/json"),
      .authorization(bearerToken: ProvenanceApp.userDefaults.apiKey)
    ]
    
    AF.request("https://api.up.com.au/api/v1/categories/\(categoryId)", method: .get, headers: headers)
      .validate()
      .responseDecodable(of: SingleCategory.self) { (response) in
        switch response.result {
        case let .success(category):
          completion(.success(category.data))
        case let .failure(error):
          completion(.failure(error))
        }
      }
  }
}
