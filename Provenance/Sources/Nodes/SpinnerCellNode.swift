import AsyncDisplayKit

final class SpinnerCellNode: ASCellNode {
  private let activityIndicatorViewBlock: ASDisplayNodeViewBlock = {
    return UIActivityIndicatorView.mediumAnimating
  }
  
  private var activityIndicator: UIActivityIndicatorView {
    return view as! UIActivityIndicatorView
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
    activityIndicator.startAnimating()
  }
}
