import Foundation

struct AvailableAccount: Codable, Hashable, Identifiable {
    var id: String
    var displayName: String
    var balance: String
}
