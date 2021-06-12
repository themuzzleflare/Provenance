import Intents

class IntentHandler: INExtension, AccountSelectionIntentHandling {
    func provideAccountOptionsCollection(for intent: AccountSelectionIntent, with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {
        var url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        let urlParams = ["page[size]": "100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Authorization": "Bearer \(appDefaults.apiKey)"
        ]
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        let accounts: [AccountType] = decodedResponse.data.map { account in
                            AccountType(identifier: account.id, display: account.attributes.displayName, subtitle: account.attributes.balance.valueShort, image: nil)
                        }
                        completion(INObjectCollection(items: accounts), nil)
                    }
                }
            }
        }
        .resume()
    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
