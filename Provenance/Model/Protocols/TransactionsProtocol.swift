import Foundation

protocol TransactionsProtocol {
    var searchController: SearchController { get set }

    var transactionsPagination: Pagination { get set }

    var noTransactions: Bool { get set }

    var transactionsError: String { get set }

    var transactions: [TransactionResource] { get set }
    
    var dateStyleObserver: NSKeyValueObservation? { get }

    var filteredTransactions: [TransactionResource] { get }
    
    func transactionsUpdates()

    func fetchTransactions()

    func display(_ transactions: [TransactionResource])

    func display(_ error: NetworkError)
}
