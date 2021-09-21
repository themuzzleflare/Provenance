import Foundation

struct Transaction: Codable {
    /// The list of transactions returned in this response.
  var data: [TransactionResource]
  
  var links: Pagination
}

extension Transaction {
  var listTransactionsIntentResponse: ListTransactionsIntentResponse {
    return .success(
      transactions: self.data.transactionTypes,
      transactionsCount: self.data.count.nsNumber
    )
  }
}
