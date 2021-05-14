import Foundation

struct Account: Decodable {
    var data: [AccountResource]
}

struct AccountResource: Decodable, Identifiable {
    var id: String
    var attributes: AccountAttribute
}

struct AccountAttribute: Decodable {
    var displayName: String
    var balance: MoneyObject
}
