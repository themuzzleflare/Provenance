import Foundation

struct Account: Hashable, Codable {
    var data: [AccountResource]
}

struct AccountResource: Hashable, Codable, Identifiable {
    var id: String
    var attributes: AccountAttribute
}

struct AccountAttribute: Hashable, Codable {
    var displayName: String
    var balance: MoneyObject
}
