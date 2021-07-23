import Intents

final class IntentHandler: INExtension, AccountSelectionIntentHandling {
    func provideAccountOptionsCollection(for intent: AccountSelectionIntent, with completion: @escaping (INObjectCollection<AccountType>?, Error?) -> Void) {

        Up.listAccounts { result in
            switch result {
            case .success(let accounts):
                let mappedAccounts = accounts.map { account in
                    AccountType(identifier: account.id, display: account.attributes.displayName, subtitle: account.attributes.balance.valueShort, image: nil)
                }

                completion(INObjectCollection(items: mappedAccounts), nil)
            case .failure(let error):
                completion(INObjectCollection(items: [AccountType(identifier: UUID().uuidString, display: "Error", subtitle: errorString(for: error), image: nil)]), nil)
            }
        }
    }

    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
