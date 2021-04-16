import Foundation

struct UpApi {
    struct Transactions {
        let listTransactions = "https://api.up.com.au/api/v1/transactions"
    }
    struct Accounts {
        let listAccounts = "https://api.up.com.au/api/v1/accounts"
        func listTransactionsByAccount(accountId: String) -> String {
            return "https://api.up.com.au/api/v1/accounts/\(accountId)/transactions"
        }
    }
    struct Categories {
        let listCategories = "https://api.up.com.au/api/v1/categories"
    }
    struct Tags {
        let listTags = "https://api.up.com.au/api/v1/tags"
    }
}
