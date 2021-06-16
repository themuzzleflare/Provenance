import Foundation

class UpAPI {
    struct Transactions {
        let listTransactions = "https://api.up.com.au/api/v1/transactions"
        
        func retrieveTransaction(transactionId: String) -> String {
            "https://api.up.com.au/api/v1/transactions/\(transactionId)"
        }

        func listTransactionsByAccount(accountId: String) -> String {
            "https://api.up.com.au/api/v1/accounts/\(accountId)/transactions"
        }
    }

    struct Accounts {
        let listAccounts = "https://api.up.com.au/api/v1/accounts"

        func retrieveAccount(accountId: String) -> String {
            "https://api.up.com.au/api/v1/accounts/\(accountId)"
        }
    }

    struct Categories {
        let listCategories = "https://api.up.com.au/api/v1/categories"
    }

    struct Tags {
        let listTags = "https://api.up.com.au/api/v1/tags"
    }
}
