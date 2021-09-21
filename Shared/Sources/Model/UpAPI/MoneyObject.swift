import Foundation

struct MoneyObject: Codable {
    /// The ISO 4217 currency code.
  var currencyCode: String
  
    /// The amount of money, formatted as a string in the relevant currency. For example, for an Australian dollar value of $10.56, this field will be "10.56". The currency symbol is not included in the string.
  var value: String
  
    /// The amount of money in the smallest denomination for the currency, as a 64-bit integer. For example, for an Australian dollar value of $10.56, this field will be 1056.
  var valueInBaseUnits: Int64
}

extension MoneyObject {
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
  
  var valueSymbol: String {
    switch valueInBaseUnits.signum() {
    case -1:
      return "-$"
    case 1:
      return "$"
    default:
      return "$"
    }
  }
  
  var valueString: String {
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
