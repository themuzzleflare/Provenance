import Intents

extension String {
  static var emptyString: String {
    return ""
  }
  
  var nsString: NSString {
    return NSString(string: self)
  }
  
  var nsDecimalNumber: NSDecimalNumber {
    return NSDecimalNumber(string: self)
  }
  
  var double: Double {
    return Double(self)!
  }
  
  var tagInputResourceIdentifier: TagInputResourceIdentifier {
    return TagInputResourceIdentifier(id: self)
  }
  
  var stringResolutionResult: INStringResolutionResult {
    return .success(with: self)
  }
  
  var addTagToTransactionTagsResolutionResult: AddTagToTransactionTagsResolutionResult {
    return .success(with: self)
  }
}

extension Array where Element == String {
  var tagInputResourceIdentifiers: [TagInputResourceIdentifier] {
    return self.map { (tag) in
      return tag.tagInputResourceIdentifier
    }
  }
  
  var stringResolutionResults: [INStringResolutionResult] {
    return self.map { (string) in
      return .success(with: string)
    }
  }
  
  var addTagToTransactionTagsResolutionResults: [AddTagToTransactionTagsResolutionResult] {
    return self.map { (string) in
      return .success(with: string)
    }
  }
}
