import Foundation

struct Account: Hashable, Codable {
    var data: [AccountResource]
    var links: Pagination
}

struct AccountResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var attributes: AccountAttribute
    var relationships: AccountRelationship
    var links: SelfLink?
}

struct AccountAttribute: Hashable, Codable {
    var displayName: String
    var accountType: AccountTypeEnum
    var balance: MoneyObject
    
    private var createdAt: String
    var createdDate: String {
        return formatDate(dateString: createdAt)
    }
    
    enum AccountTypeEnum: String, CaseIterable, Codable, Hashable, Identifiable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"
        
        var id: AccountTypeEnum {
            return self
        }
    }
}

struct AccountRelationship: Hashable, Codable {
    var transactions: TransactionsObject
}

struct TransactionsObject: Hashable, Codable {
    var links: AccountRelationshipsLink?
}

struct AccountRelationshipsLink: Hashable, Codable {
    var related: String
}
