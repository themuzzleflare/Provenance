import AsyncDisplayKit

extension ASCellNode {
  static var apiKey: ASCellNode {
    return APIKeyCellNode()
  }

  static var dateStyle: ASCellNode {
    return DateStyleCellNode()
  }

  static var aboutTop: ASCellNode {
    return AboutTopCellNode()
  }
}
