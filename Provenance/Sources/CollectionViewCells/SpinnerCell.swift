import UIKit

final class SpinnerCell: UICollectionViewCell {
  lazy var activityIndicator: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView()
    view.style = .medium
    self.contentView.addSubview(view)
    return view
  }()
  
  override func layoutSubviews() {
    super.layoutSubviews()
    let bounds = contentView.bounds
    activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
  }
}
