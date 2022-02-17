import UIKit
import AsyncDisplayKit

final class SpinnerCellNode: CellNode {
  init(sectionController: SpinnerSC) {
    super.init()
    sectionController.spinnerDelegate = self
    setViewBlock({ UIActivityIndicatorView.mediumAnimating })
  }
}

// MARK: - SpinnerDelegate

extension SpinnerCellNode: SpinnerDelegate {
  func startLoading() {
    guard isNodeLoaded else { return }
    (self.view as? UIActivityIndicatorView)?.startAnimating()
  }
}
