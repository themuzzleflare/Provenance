import Foundation

struct Account: Decodable {
    var data: [AccountResource] // The list of accounts returned in this response.

    var links: Pagination
}

struct AccountResource: Decodable, Identifiable {
    var type = "accounts" // The type of this resource: accounts

    var id: String // The unique identifier for this account.

    var attributes: AccountAttribute

    var relationships: AccountRelationship?

    var links: SelfLink?
    
    init(id: String, attributes: AccountAttribute) {
        self.id = id
        self.attributes = attributes
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
    var displayName: String // The name associated with the account in the Up application.

    var accountType: AccountTypeEnum // The bank account type of this account.

    enum AccountTypeEnum: String, Decodable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"
    }

    var balance: MoneyObject // The available balance of the account, taking into account any amounts that are currently on hold.

    private var createdAt: String // The date-time at which this account was first opened.

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
    var transactions: TransactionsLinksObject
}
