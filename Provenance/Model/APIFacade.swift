import Foundation

struct APIFacade {
    // MARK: - Decoders

    private let transactionsDecoder = ResultDecoder<[TransactionResource]> { data in
        try Array(JSONDecoder().decode(Transaction.self, from: data).data)
    }

    private let transactionDecoder = ResultDecoder<TransactionResource> { data in
        try JSONDecoder().decode(SingleTransactionResponse.self, from: data).data
    }

    private let accountsDecoder = ResultDecoder<[AccountResource]> { data in
        try Array(JSONDecoder().decode(Account.self, from: data).data)
    }

    private let accountDecoder = ResultDecoder<AccountResource> { data in
        try JSONDecoder().decode(SingleAccountResponse.self, from: data).data
    }

    private let tagsDecoder = ResultDecoder<[TagResource]> { data in
        try Array(JSONDecoder().decode(Tag.self, from: data).data)
    }

    private let categoriesDecoder = ResultDecoder<[CategoryResource]> { data in
        try Array(JSONDecoder().decode(Category.self, from: data).data)
    }

    // MARK: - Methods

    func ping(with key: String, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request, errorHandler: completion)
            .resume()
    }

    func listTransactions(completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    func listTransactions(filterBy account: AccountResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(account.id)/transactions")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    func listTransactions(filterBy tag: TagResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["filter[tag]": tag.id, "page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    func listTransactions(filterBy category: CategoryResource, completion: @escaping (Result<[TransactionResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions")!.appendingQueryParameters(["filter[category]": category.id, "page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionsDecoder.decode(result))
        }
        .resume()
    }

    func retrieveTransaction(for transaction: TransactionResource, completion: @escaping (Result<TransactionResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.transactionDecoder.decode(result))
        }
        .resume()
    }

    func listAccounts(completion: @escaping (Result<[AccountResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.accountsDecoder.decode(result))
        }
        .resume()
    }

    func retrieveAccount(for account: AccountResource, completion: @escaping (Result<AccountResource, NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts/\(account.id)")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.accountDecoder.decode(result))
        }
        .resume()
    }

    func listTags(completion: @escaping (Result<[TagResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/tags")!.appendingQueryParameters(["page[size]": "100"])
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.tagsDecoder.decode(result))
        }
        .resume()
    }

    func modifyTags(adding tags: [TagResource], to transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = authorisedRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

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

    func modifyTags(adding tag: TagResource, to transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = authorisedRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

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

    func modifyTags(removing tags: [TagResource], from transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = authorisedRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"

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

    func modifyTags(removing tag: TagResource, from transaction: TransactionResource, completion: @escaping (NetworkError?) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = authorisedRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"

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

    func listCategories(completion: @escaping (Result<[CategoryResource], NetworkError>) -> Void) {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        let request = authorisedRequest(url: url)

        URLSession.shared.dataTask(with: request) { result in
            completion(self.categoriesDecoder.decode(result))
        }
        .resume()
    }
}

private extension APIFacade {
    private func authorisedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("Bearer \(appDefaults.apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }
}
