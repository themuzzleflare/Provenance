import Foundation

struct Account: Decodable {
    var data: [AccountResource]
    var links: Pagination
}

struct AccountResource: Decodable, Identifiable {
    var type = "accounts"
    var id: String
    var attributes: AccountAttribute
    var relationships: AccountRelationship
    var links: SelfLink?
    
    init(id: String, attributes: AccountAttribute, relationships: AccountRelationship) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}

extension AccountResource: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AccountResource, rhs: AccountResource) -> Bool {
        lhs.id == rhs.id
    }
}

struct AccountAttribute: Decodable {
    var displayName: String
    var accountType: AccountTypeEnum
    enum AccountTypeEnum: String, Decodable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"
    }
    var balance: MoneyObject
    private var createdAt: String
    private var creationDateAbsolute: String {
        formatDateAbsolute(for: createdAt)
    }
    private var creationDateRelative: String {
        formatDateRelative(for: createdAt)
    }
    var creationDate: String {
        switch appDefaults.dateStyle {
            case "Absolute":
                return creationDateAbsolute
            case "Relative":
                return creationDateRelative
            default:
                return creationDateAbsolute
        }
    }
}

struct AccountRelationship: Decodable {
    var transactions: TransactionsObject
}

struct TransactionsObject: Decodable {
    var links: AccountRelationshipsLink?
}

struct AccountRelationshipsLink: Decodable {
    var related: String
}
