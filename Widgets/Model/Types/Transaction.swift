import Foundation

struct Transaction: Decodable {
    var data: [TransactionResource]
}

struct TransactionResource: Decodable, Identifiable {
    var id: String
    var attributes: Attribute
}

struct Attribute: Decodable {
    var description: String
    var amount: MoneyObject
    private var createdAt: String
    var creationDateAbsolute: String {
        return formatDateAbsolute(dateString: createdAt)
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

struct MoneyObject: Decodable {
    var value: String
    var valueInBaseUnits: Int64
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
}
