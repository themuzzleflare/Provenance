import Foundation

struct ModifyTags: Codable {
  /// The tags to add to or remove from the transaction.
  var data: [TagInputResourceIdentifier]

  init(tags: [TagResource]) {
    self.data = tags.tagInputResourceIdentifiers
  }

  init(tags: TagResource...) {
    self.data = tags.tagInputResourceIdentifiers
  }

  init(tags: [String]) {
    self.data = tags.tagInputResourceIdentifiers
  }

  init(tags: String...) {
    self.data = tags.tagInputResourceIdentifiers
  }
}
