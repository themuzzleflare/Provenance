import Foundation

class UpAPI {
    class Transactions {
        let listTransactions = "https://api.up.com.au/api/v1/transactions"
        
        func retrieveTransaction(transactionId: String) -> String {
            "https://api.up.com.au/api/v1/transactions/\(transactionId)"
        }

        func listTransactionsByAccount(accountId: String) -> String {
            "https://api.up.com.au/api/v1/accounts/\(accountId)/transactions"
        }
    }
    
    class Accounts {
        let listAccounts = "https://api.up.com.au/api/v1/accounts"

        func retrieveAccount(accountId: String) -> String {
            "https://api.up.com.au/api/v1/accounts/\(accountId)"
        }
    }

    class Categories {
        let listCategories = "https://api.up.com.au/api/v1/categories"
    }
    
    class Tags {
        let listTags = "https://api.up.com.au/api/v1/tags"
    }
}
