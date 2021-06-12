import Foundation
import UIKit
import Rswift

struct Transaction: Decodable {
    var data: [TransactionResource] // The list of transactions returned in this response.
    var links: Pagination
}

struct TransactionResource: Decodable, Hashable, Identifiable {
    private var type: String // The type of this resource: transactions
    var id: String // The unique identifier for this transaction.
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

struct Attribute: Decodable {
    private var status: TransactionStatusEnum // The current processing status of this transaction, according to whether or not this transaction has settled or is still held.
    private enum TransactionStatusEnum: String, Decodable {
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
    var rawText: String? // The original, unprocessed text of the transaction. This is often not a perfect indicator of the actual merchant, but it is useful for reconciliation purposes in some cases.
    var description: String // A short description for this transaction. Usually the merchant name for purchases.
    var message: String? // Attached message for this transaction, such as a payment message, or a transfer note.
    var holdInfo: HoldInfoObject? // If this transaction is currently in the HELD status, or was ever in the HELD status, the amount and foreignAmount of the transaction while HELD.
    var roundUp: RoundUpObject? // Details of how this transaction was rounded-up. If no Round Up was applied this field will be null.
    var cashback: CashbackObject? // If all or part of this transaction was instantly reimbursed in the form of cashback, details of the reimbursement.
    var amount: MoneyObject // The amount of this transaction in Australian dollars. For transactions that were once HELD but are now SETTLED, refer to the holdInfo field for the original amount the transaction was HELD at.
    var foreignAmount: MoneyObject? // The foreign currency amount of this transaction. This field will be null for domestic transactions. The amount was converted to the AUD amount reflected in the amount of this transaction. Refer to the holdInfo field for the original foreignAmount the transaction was HELD at.
    private var settledAt: String? // The date-time at which this transaction settled. This field will be null for transactions that are currently in the HELD status.
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
    private var createdAt: String // The date-time at which this transaction was first encountered.
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

struct HoldInfoObject: Decodable {
    var amount: MoneyObject // The amount of this transaction while in the HELD status, in Australian dollars.
    var foreignAmount: MoneyObject? // The foreign currency amount of this transaction while in the HELD status. This field will be null for domestic transactions. The amount was converted to the AUD amount reflected in the amount field.
}

struct RoundUpObject: Decodable {
    var amount: MoneyObject // The total amount of this Round Up, including any boosts, represented as a negative value.
    var boostPortion: MoneyObject? // The portion of the Round Up amount owing to boosted Round Ups, represented as a negative value. If no boost was added to the Round Up this field will be null.
}

struct CashbackObject: Decodable {
    var description: String // A brief description of why this cashback was paid.
    var amount: MoneyObject // The total amount of cashback paid, represented as a positive value.
}

struct MoneyObject: Decodable {
    private var currencyCode: String // The ISO 4217 currency code.
    var value: String // The amount of money, formatted as a string in the relevant currency. For example, for an Australian dollar value of $10.56, this field will be "10.56". The currency symbol is not included in the string.
    var valueInBaseUnits: Int64 // The amount of money in the smallest denomination for the currency, as a 64-bit integer. For example, for an Australian dollar value of $10.56, this field will be 1056.
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
                return "$"
        }
    }
    private var valueString: String {
        switch valueInBaseUnits.signum() {
            case -1:
                return value
                    .replacingOccurrences(of: "-", with: "")
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

struct Relationship: Decodable {
    var account: RelationshipAccount
    var transferAccount: RelationshipTransferAccount
    var category: RelationshipCategory
    var parentCategory: RelationshipCategory
    var tags: RelationshipTag
}

struct RelationshipAccount: Decodable {
    var data: RelationshipData
    var links: RelationshipLink?
}

struct RelationshipTransferAccount: Decodable {
    var data: RelationshipData?
    var links: RelationshipLink?
}

struct RelationshipData: Decodable, Hashable, Identifiable {
    var type: String
    var id: String
}

struct RelationshipLink: Decodable {
    var related: String
}

struct RelationshipCategory: Decodable {
    var data: RelationshipData?
    var links: RelationshipLink?
}

struct RelationshipTag: Decodable {
    var data: [RelationshipData]
    var links: SelfLink?
}

struct SelfLink: Decodable {
    var `self`: String
}

struct Pagination: Decodable {
    var prev: String? // The link to the previous page in the results. If this value is null there is no previous page.
    var next: String? // The link to the next page in the results. If this value is null there is no next page.
}
