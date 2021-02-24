import Foundation

struct Transaction: Hashable, Codable {
    var data: [TransactionResource]
    var links: Pagination
}

struct TransactionResource: Hashable, Codable, Identifiable {
    var type: String
    var id: String
    var attributes: Attribute
    var relationships: Relationship
    var links: SelfLink?
}

struct Attribute: Hashable, Codable {
    private var status: TransactionStatusEnum
    var rawText: String?
    var description: String
    var message: String?
    var holdInfo: HoldInfoObject?
    var roundUp: RoundUpObject?
    var cashback: CashbackObject?
    var amount: MoneyObject
    var foreignAmount: MoneyObject?
    
    var isSettled: Bool {
        switch status {
            case .settled: return true
            case .held: return false
        }
    }
    
    private var settledAt: String?
    var settledDate: String? {
        if settledAt != nil {
            return formatDate(dateString: settledAt!)
        } else {
            return nil
        }
    }
    
    var settledDateRelative: String? {
        if settledAt != nil {
            return formatDateRelative(dateString: settledAt!)
        } else {
            return nil
        }
    }
    
    private var createdAt: String
    var createdDate: String {
        return formatDate(dateString: createdAt)
    }
    
    var createdDateRelative: String {
        return formatDateRelative(dateString: createdAt)
    }
    
    private enum TransactionStatusEnum: String, CaseIterable, Codable, Hashable, Identifiable {
        case held = "HELD"
        case settled = "SETTLED"
        
        var id: TransactionStatusEnum {
            return self
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
    var currencyCode: String
    var value: String
    var valueInBaseUnits: Int64
    
    var transType: String {
        if valueInBaseUnits.signum() == -1 {
            return "Debit"
        } else {
            return "Credit"
        }
    }
    
    var valueSymbol: String {
        if valueInBaseUnits.signum() == -1 {
            return "-$"
        } else {
            return "$"
        }
    }
    
    var valueString: String {
        if valueInBaseUnits.signum() == -1 {
            return value.replacingOccurrences(of: "-", with: "")
        } else {
            return value
        }
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
