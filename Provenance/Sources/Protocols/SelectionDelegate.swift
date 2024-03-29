import Foundation

protocol SelectionDelegate: AnyObject {
  func didSelectItem(at indexPath: IndexPath, with id: String)

  func didDeselectItem(at indexPath: IndexPath)

  func didHighlightItem(at indexPath: IndexPath)

  func didUnhighlightItem(at indexPath: IndexPath)
}

extension SelectionDelegate {
  func didSelectItem(at indexPath: IndexPath, with id: String) {}

  func didDeselectItem(at indexPath: IndexPath) {}

  func didHighlightItem(at indexPath: IndexPath) {}

  func didUnhighlightItem(at indexPath: IndexPath) {}
}
