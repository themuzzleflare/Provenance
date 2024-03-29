import Foundation

extension NumberFormatter {
  static func currency(currencyCode: String = "AUD") -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode
    return formatter
  }

  static func currencyLong(currencyCode: String = "AUD") -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currencyISOCode
    formatter.currencyCode = currencyCode
    return formatter
  }
}
