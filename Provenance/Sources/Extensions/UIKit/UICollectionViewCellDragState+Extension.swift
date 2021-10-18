import UIKit

extension UICollectionViewCell.DragState {
  var description: String {
    switch self {
    case .none:
      return "None"
    case .lifting:
      return "Lifting"
    case .dragging:
      return "Dragging"
    @unknown default:
      return "Unknown Default"
    }
  }
}
