import Foundation
import SwiftUI

struct Transaction: Hashable, Decodable {
    var data: [TransactionResource]
    var links: Pagination
}

struct TransactionResource: Hashable, Identifiable, Decodable {
    private var type: String
    var id: String
    var attributes: Attribute
    var relationships: Relationship
    var links: SelfLink?
}

struct Attribute: Hashable, Codable {
    private var status: TransactionStatusEnum
    private enum TransactionStatusEnum: String, CaseIterable, Codable, Hashable {
        case held = "HELD"
        case settled = "SETTLED"
    }
    var isSettled: Bool {
        switch status {
            case .settled:
                return true
            case .held:
                return false
        }
    }
    var statusIcon: Image {
        switch isSettled {
            case true:
                return Image("checkmark.circle")
            case false:
                return Image("clock")
        }
    }
    var statusIconColor: Color {
        switch isSettled {
            case true:
                return .green
            case false:
                return .yellow
        }
    }
    var statusString: String {
        switch isSettled {
            case true:
                return "Settled"
            case false:
                return "Held"
        }
    }
    
    var rawText: String?
    var description: String
    var message: String?
    var holdInfo: HoldInfoObject?
    var roundUp: RoundUpObject?
    var cashback: CashbackObject?
    var amount: MoneyObject
    var foreignAmount: MoneyObject?
    
    private var settledAt: String?
    private var settledDateAbsolute: String? {
        if settledAt != nil {
            return formatDate(dateString: settledAt!)
        } else {
            return nil
        }
    }
    private var settledDateRelative: String? {
        if settledAt != nil {
            return formatDateRelative(dateString: settledAt!)
        } else {
            return nil
        }
    }
    var settlementDate: String? {
        if settledAt != nil {
            switch appDefaults.dateStyle {
                case "Absolute":
                    return settledDateAbsolute
                case "Relative":
                    return settledDateRelative
                default:
                    return settledDateAbsolute
            }
        } else {
            return nil
        }
    }
    
    private var createdAt: String
    var createdDateAbsolute: String {
        return formatDate(dateString: createdAt)
    }
    var createdDateRelative: String {
        return formatDateRelative(dateString: createdAt)
    }
    var creationDate: String {
        switch appDefaults.dateStyle {
            case "Absolute":
                return createdDateAbsolute
            case "Relative":
                return createdDateRelative
            default:
                return createdDateAbsolute
        }
    }
}

struct HoldInfoObject: Hashable, Codable {
    var amount: MoneyObject
    var foreignAmount: MoneyObject?
}

struct RoundUpObject: Hashable, Codable {
    var amount: MoneyObject
    var boostPortion: MoneyObject?
}

struct CashbackObject: Hashable, Codable {
    var description: String
    var amount: MoneyObject
}

struct MoneyObject: Hashable, Codable {
    private var currencyCode: String
    var value: String
    var valueInBaseUnits: Int64
    
    var transactionType: String {
        if valueInBaseUnits.signum() == -1 {
            return "Debit"
        } else {
            return "Credit"
        }
    }
    private var valueSymbol: String {
        if valueInBaseUnits.signum() == -1 {
            return "-$"
        } else {
            return "$"
        }
    }
    private var valueString: String {
        if valueInBaseUnits.signum() == -1 {
            return value.replacingOccurrences(of: "-", with: "")
        } else {
            return value
        }
    }
    var valueShort: String {
        return "\(valueSymbol)\(valueString)"
    }
    var valueLong: String {
        return "\(valueSymbol)\(valueString) \(currencyCode)"
    }
}

struct Relationship: Hashable, Codable {
    var account: RelationshipAccount
    var category: RelationshipCategory
    var parentCategory: RelationshipCategory
    var tags: RelationshipTag
}

struct RelationshipAccount: Hashable, Codable {
    var data: RelationshipData
    var links: RelationshipLink?
}

struct RelationshipData: Hashable, Codable, Identifiable {
    var type: String
    var id: String
}

struct RelationshipLink: Hashable, Codable {
    var related: String
}

struct RelationshipCategory: Hashable, Codable {
    var data: RelationshipData?
    var links: RelationshipLink?
}

struct RelationshipTag: Hashable, Codable {
    var data: [RelationshipData]
    var links: SelfLink?
}

struct SelfLink: Hashable, Codable {
    var `self`: String
}

struct Pagination: Hashable, Codable {
    var prev: String?
    var next: String?
}
