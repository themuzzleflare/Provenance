import AsyncDisplayKit

extension ASSizeRange {
  /// `ASSizeRange(min: .cellNode(height: minHeight), max: .cellNode(height: maxHeight))`.
  static func cellNode(minHeight: CGFloat, maxHeight: CGFloat) -> ASSizeRange {
    return ASSizeRange(min: .cellNode(height: minHeight), max: .cellNode(height: maxHeight))
  }
  
  /// `ASSizeRange(min: .separator, max: .separator)`.
  static var separator: ASSizeRange {
    return ASSizeRange(min: .separator, max: .separator)
  }
}
