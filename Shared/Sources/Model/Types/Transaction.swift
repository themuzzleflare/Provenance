import Foundation
import UIKit
import SwiftUI
import SwiftDate

#if canImport(Rswift)
import Rswift
#endif

struct Transaction: Codable {
    var data: [TransactionResource] // The list of transactions returned in this response.

    var links: Pagination
}

struct TransactionResource: Codable, Identifiable {
    var type = "transactions" // The type of this resource: transactions

    var id: String // The unique identifier for this transaction.

    var attributes: TransactionAttribute

    var relationships: TransactionRelationship

    var links: SelfLink?

    init(id: String, attributes: TransactionAttribute, relationships: TransactionRelationship) {
        self.id = id
        self.attributes = attributes
        self.relationships = relationships
    }
}

extension TransactionResource: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TransactionResource, rhs: TransactionResource) -> Bool {
        lhs.id == rhs.id
    }
}

struct TransactionAttribute: Codable {
    // The current processing status of this transaction, according to whether or not this transaction has settled or is still held.
    private var status: TransactionStatusEnum

    private enum TransactionStatusEnum: String, Codable {
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

    var statusString: String {
        switch isSettled {
        case true:
            return "Settled"
        case false:
            return "Held"
        }
    }

    #if canImport(Rswift)
    var statusIcon: UIImage {
        switch isSettled {
        case true:
            return R.image.checkmarkCircle()!
        case false:
            return R.image.clock()!
        }
    }
    #endif

    var statusIconImage: Image {
        switch isSettled {
        case true:
            return Image(systemName: "checkmark.circle")
        case false:
            return Image(systemName: "clock")
        }
    }

    // The original, unprocessed text of the transaction. This is often not a perfect indicator of the actual merchant, but it is useful for reconciliation purposes in some cases.
    var rawText: String?

    // A short description for this transaction. Usually the merchant name for purchases.
    var transactionDescription: String

    var message: String? // Attached message for this transaction, such as a payment message, or a transfer note.

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
            return formatDateAbsolute(for: settledAt!)
        }
    }

    private var settlementDateRelative: String? {
        switch settledAt {
        case nil:
            return nil
        default:
            return formatDateRelative(for: settledAt!)
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

    var createdAtDate: Date {
        let date = createdAt.toDate()!
        return date.dateAt(.startOfDay).date
    }

    var creationDayMonthYear: String {
        createdAtDate.toString(.date(.medium))
    }

    var creationDateAbsolute: String {
        formatDateAbsolute(for: createdAt)
    }

    var creationDateRelative: String {
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

    enum CodingKeys: String, CodingKey {
        case transactionDescription = "description"
        case status, rawText, amount, createdAt
    }
}

struct HoldInfoObject: Codable {
    var amount: MoneyObject // The amount of this transaction while in the HELD status, in Australian dollars.

    // The foreign currency amount of this transaction while in the HELD status. This field will be null for domestic transactions. The amount was converted to the AUD amount reflected in the amount field.
    var foreignAmount: MoneyObject?
}

struct RoundUpObject: Codable {
    var amount: MoneyObject // The total amount of this Round Up, including any boosts, represented as a negative value.

    // The portion of the Round Up amount owing to boosted Round Ups, represented as a negative value. If no boost was added to the Round Up this field will be null.
    var boostPortion: MoneyObject?
}

struct CashbackObject: Codable {
    var description: String // A brief description of why this cashback was paid.

    var amount: MoneyObject // The total amount of cashback paid, represented as a positive value.
}

struct TransactionRelationship: Codable {
    var account: TransactionRelationshipAccount

    var transferAccount: TransactionRelationshipTransferAccount

    var category: TransactionRelationshipCategory

    var parentCategory: TransactionRelationshipCategory

    var tags: TransactionRelationshipTag
}

struct TransactionRelationshipAccount: Codable {
    var data: RelationshipData

    var links: RelatedLink?
}

struct TransactionRelationshipTransferAccount: Codable {
    var data: RelationshipData?

    var links: RelatedLink?
}

struct TransactionRelationshipCategory: Codable {
    var data: RelationshipData?

    var links: RelatedLink?
}

struct TransactionRelationshipTag: Codable {
    var data: [RelationshipData]

    var links: SelfLink?
}

struct SortedTransactions: Identifiable {
    var id: Date

    var transactions: [TransactionResource]

    init(id: Date, transactions: [TransactionResource]) {
        self.id = id
        self.transactions = transactions
    }
}

extension SortedTransactions: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SortedTransactions, rhs: SortedTransactions) -> Bool {
        lhs.id == rhs.id
    }
}
