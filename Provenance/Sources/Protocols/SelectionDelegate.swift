import Foundation

protocol SelectionDelegate: AnyObject {
  func didSelectItem(at indexPath: IndexPath)
  
  func didDeselectItem(at indexPath: IndexPath)
  
  func didHighlightItem(at indexPath: IndexPath)
  
  func didUnhighlightItem(at indexPath: IndexPath)
}

extension SelectionDelegate {
  func didSelectItem(at indexPath: IndexPath) {
    return
  }
  
  func didDeselectItem(at indexPath: IndexPath) {
    return
  }
  
  func didHighlightItem(at indexPath: IndexPath) {
    return
  }
  
  func didUnhighlightItem(at indexPath: IndexPath) {
    return
  }
}
