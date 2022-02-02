import Foundation
import Intents

extension String {
  var url: URL? {
    return URL(string: self)
  }

  var nsString: NSString {
    return NSString(string: self)
  }

  var nsDecimalNumber: NSDecimalNumber {
    return NSDecimalNumber(string: self)
  }

  var tagResource: TagResource {
    return TagResource(id: self)
  }

  var stringResolutionResult: INStringResolutionResult {
    return .success(with: self)
  }

  var addTagToTransactionTagsResolutionResult: AddTagToTransactionTagsResolutionResult {
    return .success(with: self)
  }
}

// MARK: -

extension Array where Element == String {
  var tagResources: [TagResource] {
    return self.map { (tag) in
      return tag.tagResource
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
