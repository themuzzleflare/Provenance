import Foundation
import UIKit
import Rswift

struct Transaction: Hashable, Codable {
    // The list of transactions returned in this response.
    var data: [TransactionResource]
    var links: Pagination
}

struct TransactionResource: Hashable, Codable, Identifiable {
    // The type of this resource: transactions
    private var type: String
    // The unique identifier for this transaction.
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
    // The current processing status of this transaction, according to whether or not this transaction has settled or is still held.
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
    var statusString: String {
        switch isSettled {
            case true:
                return "Settled"
            case false:
                return "Held"
        }
    }
    // The original, unprocessed text of the transaction. This is often not a perfect indicator of the actual merchant, but it is useful for reconciliation purposes in some cases.
    var rawText: String?
    // A short description for this transaction. Usually the merchant name for purchases.
    var description: String
    // Attached message for this transaction, such as a payment message, or a transfer note.
    var message: String?
    // If this transaction is currently in the HELD status, or was ever in the HELD status, the amount and foreignAmount of the transaction while HELD.
    var holdInfo: HoldInfoObject?
    // Details of how this transaction was rounded-up. If no Round Up was applied this field will be null.
    var roundUp: RoundUpObject?
    // If all or part of this transaction was instantly reimbursed in the form of cashback, details of the reimbursement.
    var cashback: CashbackObject?
    // The amount of this transaction in Australian dollars. For transactions that were once HELD but are now SETTLED, refer to the holdInfo field for the original amount the transaction was HELD at.
    var amount: MoneyObject
    // The foreign currency amount of this transaction. This field will be null for domestic transactions. The amount was converted to the AUD amount reflected in the amount of this transaction. Refer to the holdInfo field for the original foreignAmount the transaction was HELD at.
    var foreignAmount: MoneyObject?
    // The date-time at which this transaction settled. This field will be null for transactions that are currently in the HELD status.
    private var settledAt: String?
    private var settlementDateAbsolute: String? {
        switch settledAt {
            case nil:
                return nil
            default:
                return formatDateAbsolute(dateString: settledAt!)
        }
    }
    private var settlementDateRelative: String? {
        switch settledAt {
            case nil:
                return nil
            default:
                return formatDateRelative(dateString: settledAt!)
        }
    }
    var settlementDate: String? {
        switch settledAt {
            case nil:
                return nil
            default:
                switch appDefaults.dateStyle {
                    case "Absolute":
                        return settlementDateAbsolute
                    case "Relative":
                        return settlementDateRelative
                    default:
                        return settlementDateAbsolute
                }
        }
    }
    // The date-time at which this transaction was first encountered.
    private var createdAt: String
    private var creationDateAbsolute: String {
        return formatDateAbsolute(dateString: createdAt)
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
        switch valueInBaseUnits.signum() {
            case -1:
                return "Debit"
            case 1:
                return "Credit"
            default:
                return "Amount"
        }
    }
    private var valueSymbol: String {
        switch valueInBaseUnits.signum() {
            case -1:
                return "-$"
            case 1:
                return "$"
            default:
                return ""
        }
    }
    private var valueString: String {
        switch valueInBaseUnits.signum() {
            case -1:
                return value.replacingOccurrences(of: "-", with: "")
            case 1:
                return value
            default:
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
