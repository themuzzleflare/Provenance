import Foundation

struct Account: Decodable {
    var data: [AccountResource]
    var links: Pagination
}

struct AccountResource: Decodable, Hashable, Identifiable {
    private var type: String
    var id: String
    var attributes: AccountAttribute
    var relationships: AccountRelationship
    var links: SelfLink?
    
    init(type: String, id: String, attributes: AccountAttribute, relationships: AccountRelationship, links: SelfLink? = nil) {
        self.type = type
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
        self.links = links
    }
    
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
        formatDateAbsolute(dateString: createdAt)
    }
    private var creationDateRelative: String {
        formatDateRelative(dateString: createdAt)
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
