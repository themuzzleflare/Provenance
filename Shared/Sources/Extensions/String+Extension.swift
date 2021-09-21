import Foundation

extension String {
  static var emptyString: String {
    return ""
  }
  
  var nsString: NSString {
    return NSString(string: self)
  }
  
  var tagInputResourceIdentifier: TagInputResourceIdentifier {
    return TagInputResourceIdentifier(id: self)
  }
}

extension Array where Element == String {
  var tagInputResourceIdentifiers: [TagInputResourceIdentifier] {
    return self.map { (tag) in
      return tag.tagInputResourceIdentifier
    }
  }
}
