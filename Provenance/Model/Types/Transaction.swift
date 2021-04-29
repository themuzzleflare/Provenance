import Foundation
import UIKit
import Rswift

struct Transaction: Hashable, Codable {
    var data: [TransactionResource]
    var links: Pagination
}

struct TransactionResource: Hashable, Codable, Identifiable {
    private var type: String
    var id: String
    var attributes: Attribute
    var relationships: Relationship
    var links: SelfLink?
    
    init(type: String, id: String, attributes: Attribute, relationships: Relationship, links: SelfLink? = nil) {
        self.type = type
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
        self.links = links
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TransactionResource, rhs: TransactionResource) -> Bool {
        lhs.id == rhs.id
    }
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
    var statusIcon: UIImage {
        switch isSettled {
            case true:
                return R.image.checkmarkCircle()!
            case false:
                return R.image.clock()!
        }
    }
    var statusIconView: UIImageView {
        let view = UIImageView(image: statusIcon)
        view.tintColor = isSettled ? .systemGreen : .systemYellow
        return view
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
    private var settlementDateAbsolute: String? {
        if settledAt != nil {
            return formatDate(dateString: settledAt!)
        } else {
            return nil
        }
    }
    private var settlementDateRelative: String? {
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
                    return settlementDateAbsolute
                case "Relative":
                    return settlementDateRelative
                default:
                    return settlementDateAbsolute
            }
        } else {
            return nil
        }
    }
    
    private var createdAt: String
    private var creationDateAbsolute: String {
        return formatDate(dateString: createdAt)
    }
    private var creationDateRelative: String {
        return formatDateRelative(dateString: createdAt)
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
