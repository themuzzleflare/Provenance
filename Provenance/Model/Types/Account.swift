import Foundation

struct Account: Hashable, Codable {
    var data: [AccountResource]
    var links: Pagination
}

struct AccountResource: Hashable, Codable, Identifiable {
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

struct AccountAttribute: Hashable, Codable {
    var displayName: String
    
    var accountType: AccountTypeEnum
    enum AccountTypeEnum: String, CaseIterable, Codable, Hashable, Identifiable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"
        
        var id: AccountTypeEnum {
            return self
        }
    }
    
    var balance: MoneyObject
    
    private var createdAt: String
    private var creationDateAbsolute: String {
        return formatDate(dateString: createdAt)
    }
    private var creationDateRelative: String {
        return formatDateRelative(dateString: createdAt)
    }
    var creationDate: String {
        switch appDefaults.string(forKey: "dateStyle") {
            case "Absolute", .none: return creationDateAbsolute
            case "Relative": return creationDateRelative
            default: return creationDateAbsolute
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
