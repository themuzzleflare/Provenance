import UIKit

final class HeaderView: UICollectionReusableView {
  private let dateLabel = UILabel()
  private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
  
  var dateText: String? {
    get {
      return dateLabel.text
    }
    set {
      dateLabel.text = newValue
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    blurView.frame = bounds
    dateLabel.frame = blurView.contentView.bounds.inset(by: .sectionHeader)
  }
  
  private func configure() {
    addSubview(blurView)
    blurView.contentView.addSubview(dateLabel)
    dateLabel.font = .circularStdBook(size: .labelFontSize)
  }
}
