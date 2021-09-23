import Foundation
import CoreGraphics

extension Int {
    /// NSNumber.
  var nsNumber: NSNumber {
    return NSNumber(value: self)
  }
  
    /// UInt.
  var uInt: UInt {
    return UInt(self)
  }
  
    /// Double.
  var double: Double {
    return Double(self)
  }
  
    /// Float.
  var float: Float {
    return Float(self)
  }
  
    /// CGFloat.
  var cgFloat: CGFloat {
    return CGFloat(self)
  }
  
  var statusTitle: String {
    switch self {
    case 200, 201, 204:
      return "Successful response"
    case 400:
      return "Bad request"
    case 401:
      return "Not authorised"
    case 403:
      return "Forbidden"
    case 404:
      return "Not found"
    case 422:
      return "Invalid request"
    case 429:
      return "Too many requests"
    case 500, 502, 503, 504:
      return "Server-side error"
    default:
      return "Network error"
    }
  }
  
  var statusDescription: String {
    switch self {
    case 200:
      return "Everything worked as intended."
    case 201:
      return "A new resource was created successfully—Typically used with POST requests."
    case 204:
      return "No content—typically used with DELETE requests."
    case 400:
      return "Typically a problem with the query string or an encoding error."
    case 401:
      return "The request was not authenticated."
    case 403:
      return "Each transaction may have up to 6 tags."
    case 404:
      return "Either the endpoint does not exist, or the requested resource does not exist."
    case 422:
      return "The request contains invalid data and was not processed."
    case 429:
      return "You have been rate limited—try later, ideally with exponential backoff."
    case 500, 502, 503, 504:
      return "Try again later."
    default:
      return "Unknown network error."
    }
  }
}
