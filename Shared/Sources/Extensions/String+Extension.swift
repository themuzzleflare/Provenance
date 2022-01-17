import Intents

extension String {
  var integer: Int? {
    return Int(self)
  }

  var url: URL? {
    return URL(string: self)
  }

  var nsString: NSString {
    return NSString(string: self)
  }

  var nsDecimalNumber: NSDecimalNumber {
    return NSDecimalNumber(string: self)
  }

  var tagInputResourceIdentifier: TagInputResourceIdentifier {
    return TagInputResourceIdentifier(id: self)
  }

  var categoryInputResourceIdentifier: CategoryInputResourceIdentifier {
    return CategoryInputResourceIdentifier(id: self)
  }

  var stringResolutionResult: INStringResolutionResult {
    return .success(with: self)
  }

  var addTagToTransactionTagsResolutionResult: AddTagToTransactionTagsResolutionResult {
    return .success(with: self)
  }

  func split(count: Int) -> [String] {
    let chars = Array(self)
    return stride(from: 0, to: chars.count, by: count)
      .map { chars[$0 ..< min($0 + count, chars.count)] }
      .map { String($0) }
  }
}

// MARK: -

extension Array where Element == String {
  var tagInputResourceIdentifiers: [TagInputResourceIdentifier] {
    return self.map { (tag) in
      return tag.tagInputResourceIdentifier
    }
  }

  var stringResolutionResults: [INStringResolutionResult] {
    return self.map { (string) in
      return string.stringResolutionResult
    }
  }

  var addTagToTransactionTagsResolutionResults: [AddTagToTransactionTagsResolutionResult] {
    return self.map { (string) in
      return string.addTagToTransactionTagsResolutionResult
    }
  }
}
