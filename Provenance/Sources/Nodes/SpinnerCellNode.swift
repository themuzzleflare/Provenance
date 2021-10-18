import AsyncDisplayKit

final class SpinnerCellNode: ASCellNode {
  private let activityIndicatorViewBlock: ASDisplayNodeViewBlock = {
    return UIActivityIndicatorView.mediumAnimating
  }
  
  init(_ sectionController: SpinnerSC? = nil) {
    super.init()
    sectionController?.spinnerDelegate = self
    setViewBlock(activityIndicatorViewBlock)
  }
}

// MARK: - SpinnerDelegate

extension SpinnerCellNode: SpinnerDelegate {
  func startLoading() {
    guard isNodeLoaded else { return }
    (self.view as! UIActivityIndicatorView).startAnimating()
  }
}
