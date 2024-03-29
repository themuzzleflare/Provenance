import Foundation

struct Account: Codable {
    var data: [AccountResource] // The list of accounts returned in this response.

    var links: Pagination
}

struct AccountResource: Codable, Identifiable {
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

struct AccountAttribute: Codable {
    var displayName: String // The name associated with the account in the Up application.

    var accountType: AccountTypeEnum // The bank account type of this account.

    enum AccountTypeEnum: String, Codable {
        case saver = "SAVER"
        case transactional = "TRANSACTIONAL"
    }

    // The available balance of the account, taking into account any amounts that are currently on hold.
    var balance: MoneyObject

    private var createdAt: String // The date-time at which this account was first opened.

    private var creationDateAbsolute: String { return formatDateAbsolute(for: createdAt) }

    private var creationDateRelative: String { return formatDateRelative(for: createdAt) }

    var creationDate: String {
        switch appDefaults.dateStyle {
        case "Absolute": return creationDateAbsolute
        case "Relative": return creationDateRelative
        default: return creationDateAbsolute
        }
    }
}

struct AccountRelationship: Codable {
    var transactions: TransactionsLinksObject
}
