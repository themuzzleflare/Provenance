import Foundation

struct Up {
    // MARK: - Decoders
    
    private static let transactionsDecoder = ResultDecoder<[TransactionResource]> { data in
        try Array(JSONDecoder().decode(Transaction.self, from: data).data)
    }
    
    private static let transactionDecoder = ResultDecoder<TransactionResource> { data in
        try JSONDecoder().decode(SingleTransaction.self, from: data).data
    }
    
    private static let accountsDecoder = ResultDecoder<[AccountResource]> { data in
        try Array(JSONDecoder().decode(Account.self, from: data).data)
    }
    
    private static let accountDecoder = ResultDecoder<AccountResource> { data in
        try JSONDecoder().decode(SingleAccount.self, from: data).data
    }
    
    private static let tagsDecoder = ResultDecoder<[TagResource]> { data in
        try Array(JSONDecoder().decode(Tag.self, from: data).data)
    }
    
    private static let categoriesDecoder = ResultDecoder<[CategoryResource]> { data in
        try Array(JSONDecoder().decode(Category.self, from: data).data)
    }

    private static let categoryDecoder = ResultDecoder<CategoryResource> { data in
        try JSONDecoder().decode(SingleCategory.self, from: data).data
    }
    
    // MARK: - Methods

    static func ping(with key: String, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!

        var request = URLRequest(url: url)

        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }

    @available(iOS 15.0, *) static func listTransactions() async throws -> [TransactionResource] {
        try await withCheckedThrowingContinuation { continuation in
            listTransactions { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }

    static func listTransactions(completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func listTransactions(filterBy account: AccountResource) async throws -> [TransactionResource] {
        try await withCheckedThrowingContinuation { continuation in
            listTransactions(filterBy: account) { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listTransactions(filterBy account: AccountResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(account.id)/transactions")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func listTransactions(filterBy tag: TagResource) async throws -> [TransactionResource] {
        try await withCheckedThrowingContinuation { continuation in
            listTransactions(filterBy: tag) { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listTransactions(filterBy tag: TagResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["filter[tag]": tag.id, "page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func listTransactions(filterBy category: CategoryResource) async throws -> [TransactionResource] {
        try await withCheckedThrowingContinuation { continuation in
            listTransactions(filterBy: category) { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listTransactions(filterBy category: CategoryResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["filter[category]": category.id, "page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveLatestTransaction() async throws -> [TransactionResource] {
        try await withCheckedThrowingContinuation { continuation in
            retrieveLatestTransaction { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }

    static func retrieveLatestTransaction(completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["page[size]": "1"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveTransaction(for transaction: TransactionResource) async throws -> TransactionResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveTransaction(for: transaction) { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }

    static func retrieveTransaction(for transaction: TransactionResource, completion: @escaping (Result<TransactionResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)")!
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveTransaction(for transactionId: String) async throws -> TransactionResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveTransaction(for: transactionId) { result in
                switch result {
                    case .success(let transactions):
                        continuation.resume(returning: transactions)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }

    static func retrieveTransaction(for transactionId: String, completion: @escaping (Result<TransactionResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transactionId)")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func listAccounts() async throws -> [AccountResource] {
        try await withCheckedThrowingContinuation { continuation in
            listAccounts { result in
                switch result {
                    case .success(let accounts):
                        continuation.resume(returning: accounts)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listAccounts(completion: @escaping (Result<[AccountResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.accountsDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveAccount(for account: AccountResource) async throws -> AccountResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveAccount(for: account) { result in
                switch result {
                    case .success(let account):
                        continuation.resume(returning: account)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func retrieveAccount(for account: AccountResource, completion: @escaping (Result<AccountResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(account.id)")!
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.accountDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveAccount(for accountId: String) async throws -> AccountResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveAccount(for: accountId) { result in
                switch result {
                    case .success(let account):
                        continuation.resume(returning: account)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }

    static func retrieveAccount(for accountId: String, completion: @escaping (Result<AccountResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(accountId)")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.accountDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func listTags() async throws -> [TagResource] {
        try await withCheckedThrowingContinuation { continuation in
            listTags { result in
                switch result {
                    case .success(let tags):
                        continuation.resume(returning: tags)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listTags(completion: @escaping (Result<[TagResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/tags")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.tagsDecoder.decode(result))
        }
        .resume()
    }
    
    static func modifyTags(adding tags: [TagResource], to transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!

        var request = authorisedRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let tagsObject = tags.map { tag in
            TagInputResourceIdentifier(id: tag.id)
        }
        
        let bodyObject = ModifyTags(data: tagsObject)
        
        do {
            request.httpBody = try JSONEncoder().encode(bodyObject)
        } catch {
            completion(.encodingError(error))
            return
        }
        
        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }
    
    static func modifyTags(adding tag: TagResource, to transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!

        var request = authorisedRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let tagsObject = [TagInputResourceIdentifier(id: tag.id)]
        
        let bodyObject = ModifyTags(data: tagsObject)
        
        do {
            request.httpBody = try JSONEncoder().encode(bodyObject)
        } catch {
            completion(.encodingError(error))
            return
        }
        
        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }
    
    static func modifyTags(removing tags: [TagResource], from transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!

        var request = authorisedRequest(url: url)

        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let tagsObject = tags.map { tag in
            TagInputResourceIdentifier(id: tag.id)
        }
        
        let bodyObject = ModifyTags(data: tagsObject)
        
        do {
            request.httpBody = try JSONEncoder().encode(bodyObject)
        } catch {
            completion(.encodingError(error))
            return
        }
        
        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }
    
    static func modifyTags(removing tag: TagResource, from transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!

        var request = authorisedRequest(url: url)

        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let tagsObject = [TagInputResourceIdentifier(id: tag.id)]
        
        let bodyObject = ModifyTags(data: tagsObject)
        
        do {
            request.httpBody = try JSONEncoder().encode(bodyObject)
        } catch {
            completion(.encodingError(error))
            return
        }
        
        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }

    @available(iOS 15.0, *) static func listCategories() async throws -> [CategoryResource] {
        try await withCheckedThrowingContinuation { continuation in
            listCategories { result in
                switch result {
                    case .success(let categories):
                        continuation.resume(returning: categories)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func listCategories(completion: @escaping (Result<[CategoryResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.categoriesDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveCategory(for category: CategoryResource) async throws -> CategoryResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveCategory(for: category) { result in
                switch result {
                    case .success(let category):
                        continuation.resume(returning: category)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func retrieveCategory(for category: CategoryResource, completion: @escaping (Result<CategoryResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/categories/\(category.id)")!
        let request = authorisedRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { result in
            completion(self.categoryDecoder.decode(result))
        }
        .resume()
    }

    @available(iOS 15.0, *) static func retrieveCategory(for categoryId: String) async throws -> CategoryResource {
        try await withCheckedThrowingContinuation { continuation in
            retrieveCategory(for: categoryId) { result in
                switch result {
                    case .success(let category):
                        continuation.resume(returning: category)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func retrieveCategory(for categoryId: String, completion: @escaping (Result<CategoryResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/categories/\(categoryId)")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.categoryDecoder.decode(result))
        }
        .resume()
    }
}

private extension Up {
    private static func authorisedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)

        request.addValue("Bearer \(appDefaults.apiKey)", forHTTPHeaderField: "Authorization")

        return request
    }
}
