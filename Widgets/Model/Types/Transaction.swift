import Foundation

struct Transaction: Hashable, Codable {
    var data: [TransactionResource]
}

struct TransactionResource: Hashable, Identifiable, Codable {
    var id: String
    var attributes: Attribute
}

struct Attribute: Hashable, Codable {
    var description: String
    var amount: MoneyObject
    
    private var createdAt: String
    var creationDateAbsolute: String {
        return formatDate(dateString: createdAt)
    }
    var creationDateRelative: String {
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

struct MoneyObject: Hashable, Codable {
    var value: String
    var valueInBaseUnits: Int64

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
}
