import Foundation

extension ListTransactionsIntentResponse {
  static func success(transactions: [TransactionType], transactionsCount: NSNumber) -> ListTransactionsIntentResponse {
    let intentResponse = ListTransactionsIntentResponse(code: .success, userActivity: nil)
    intentResponse.transactions = transactions
    intentResponse.transactionsCount = transactionsCount
    return intentResponse
  }
}
